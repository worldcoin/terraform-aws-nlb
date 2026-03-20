locals {
  default_tags = {
    "elbv2.k8s.aws/cluster"   = var.cluster_name
    "${var.tag_prefix}/stack" = var.tag_stack != "" ? var.tag_stack : var.application
  }
}
