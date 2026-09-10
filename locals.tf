locals {
  cluster_tag = var.cluster_tag != "" ? var.cluster_tag : var.cluster_name

  default_tags = {
    "elbv2.k8s.aws/cluster"   = local.cluster_tag
    "${var.tag_prefix}/stack" = var.tag_stack != "" ? var.tag_stack : var.application
  }
}
