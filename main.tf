data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_region" "current" {}

resource "kubernetes_namespace" "this" {
  count = var.namespace == "" ? 1 - local.argocd_enabled : 0
  metadata {
    name = var.namespace_name
  }
}

resource "local_file" "namespace" {
  count = local.argocd_enabled
  content = yamlencode({
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = local.namespace
    }
  })
  filename = "${path.root}/${var.argocd.path}/ns-${local.namespace}.yaml"
}

locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = coalescelist(var.namespace == "" && local.argocd_enabled > 0 ? [{ "metadata" = [{ "name" = var.namespace_name }] }] : kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name
}

#Elasticsearch
resource "helm_release" "elastic" {
  count = 1 - local.argocd_enabled

  name          = local.elastic_name
  repository    = local.elastic_repository
  chart         = local.elastic_chart
  version       = var.elastic_chart_version
  namespace     = local.namespace
  recreate_pods = true
  timeout       = 1200

  dynamic "set" {
    for_each = merge(local.elastic_conf)

    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "local_file" "elastic" {
  count    = local.argocd_enabled
  content  = yamlencode(local.elastic_application)
  filename = "${path.root}/${var.argocd.path}/${local.elastic_name}.yaml"
}

#Kibana
resource "helm_release" "kibana" {
  count = 1 - local.argocd_enabled

  name          = local.kibana_name
  repository    = local.kibana_repository
  chart         = local.kibana_chart
  version       = var.kibana_chart_version
  namespace     = local.namespace
  recreate_pods = true
  timeout       = 1200

  dynamic "set" {
    for_each = merge(local.kibana_conf)

    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "local_file" "kibana" {
  count    = local.argocd_enabled
  content  = yamlencode(local.kibana_application)
  filename = "${path.root}/${var.argocd.path}/${local.kibana_name}.yaml"
}

#Filebeat
# resource "helm_release" "filebeat" {
#   count = 1 - local.argocd_enabled

#   name          = local.filebeat_name
#   repository    = local.filebeat_repository
#   chart         = local.filebeat_chart
#   version       = var.filebeat_chart_version
#   namespace     = local.namespace
#   recreate_pods = true
#   timeout       = 1200

#   dynamic "set" {
#     for_each = local.filebeat_conf

#     content {
#       name  = set.key
#       value = set.value
#     }
#   }
# }

resource "local_file" "filebeat" {
  count    = local.argocd_enabled
  content  = yamlencode(local.filebeat_application)
  filename = "${path.root}/${var.argocd.path}/${local.filebeat_name}.yaml"
}

locals {
  #elasticsearch
  elastic_name       = "elasticsearch"
  elastic_repository = "https://helm.elastic.co/"
  elastic_chart      = "elasticsearch"
  elastic_conf       = merge(local.elastic_conf_defaults, var.elastic_conf)
  #kibana
  kibana_name       = "kibana"
  kibana_repository = "https://helm.elastic.co/"
  kibana_chart      = "kibana"
  kibana_conf       = merge(local.kibana_conf_defaults, var.kibana_conf)
  #filebeat
  filebeat_name       = "filebeat"
  filebeat_repository = "https://helm.elastic.co/"
  filebeat_chart      = "filebeat"
  filebeat_conf       = local.filebeat_conf_merge

  elastic_conf_defaults = {
    "replicas"                                       = var.elasticReplicas
    "minimumMasterNodes"                             = var.elasticMinMasters
    "volumeClaimTemplate.resources.requests.storage" = var.elasticDataSize
  }
  kibana_conf_defaults = {
    "elasticsearchHosts"        = "http://elasticsearch-master:9200"
    "ingress.enabled"           = "true"
    "ingress.hosts[0]"          = "kibana.${var.domains[0]}"
    "ingress.tls[0].secretName" = "kibana-tls"
    "ingress.tls[0].hosts[0]"   = "kibana.${var.domains[0]}"
  }

  filebeat_conf_merge = {
    "daemonset.filebeatConfig" = {
      "filebeat\\.yml" = merge(local.filebeat_conf_defaults, var.filebeat_conf)
    }
  }

  filebeat_conf_defaults = {
    "output.elasticsearch" = {
      "host"  = "$\\{NODE_NAME\\}"
      "hosts" = "$\\{ELASTICSEARCH_HOSTS:elasticsearch-master:9200\\}"
    }
  }

  elastic_application = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = local.elastic_name
      "namespace" = var.argocd.namespace
    }
    "spec" = {
      "destination" = {
        "namespace" = local.namespace
        "server"    = "https://kubernetes.default.svc"
      }
      "project" = "default"
      "source" = {
        "repoURL"        = local.elastic_repository
        "targetRevision" = var.elastic_chart_version
        "chart"          = local.elastic_chart
        "helm" = {
          "parameters" = values({
            for key, value in local.elastic_conf :
            key => {
              "name"  = key
              "value" = tostring(value)
            }
          })
        }
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }
  kibana_application = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = local.kibana_name
      "namespace" = var.argocd.namespace
    }
    "spec" = {
      "destination" = {
        "namespace" = local.namespace
        "server"    = "https://kubernetes.default.svc"
      }
      "project" = "default"
      "source" = {
        "repoURL"        = local.kibana_repository
        "targetRevision" = var.kibana_chart_version
        "chart"          = local.kibana_chart
        "helm" = {
          "parameters" = concat(
            values({
              for key, value in local.kibana_conf :
              key => {
                "name"  = key
                "value" = tostring(value)
              }
            }),
            values({
              for key, value in var.ingress_annotations :
              key => {
                "name"        = "ingress.annotations.${replace(key, ".", "\\.")}"
                "value"       = tostring(value)
                "forceString" = true
              }
            })
          )
        }
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }
  filebeat_application = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = local.filebeat_name
      "namespace" = var.argocd.namespace
    }
    "spec" = {
      "destination" = {
        "namespace" = local.namespace
        "server"    = "https://kubernetes.default.svc"
      }
      "project" = "default"
      "source" = {
        "repoURL"        = local.filebeat_repository
        "targetRevision" = var.filebeat_chart_version
        "chart"          = local.filebeat_chart
        "helm" = {
          "values" = yamlencode(local.filebeat_conf)
        }
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
    }
  }
}
