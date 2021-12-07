output "cluster_name" {
  value = var.cluster_name
}

output "depends_on" {
  value = join(", ", var.module_depends_on)
}

output "cluster_arn" {
  value = data.aws_eks_cluster.this.arn
}