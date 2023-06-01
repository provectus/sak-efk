variable "namespace" {
  type        = string
  default     = ""
  description = "A name of the existing namespace"
}

variable "elastic_chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "7.10.1"
}

variable "kibana_chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "7.10.1"
}

variable "filebeat_chart_version" {
  type        = string
  description = "A Helm Chart version"
  default     = "7.10.1"
}

variable "domains" {
  type        = list(string)
  default     = ["local"]
  description = "A list of domains to use for ingresses"
}

variable "argocd" {
  type        = map(string)
  description = "A set of values for enabling deployment through ArgoCD"
  default     = {}
}

variable "filebeat_conf" {
  type        = any
  description = "A custom configuration for deployment"
  default     = {}
}

variable "kibana_conf" {
  type        = map(string)
  description = "A custom configuration for deployment"
  default     = {}
}

variable "elastic_conf" {
  type        = map(string)
  description = "A custom configuration for deployment"
  default     = {}
}

variable "ingress_annotations" {
  type        = map(string)
  description = "A set of annotations for ArgoCD Ingress"
  default     = {}
}
