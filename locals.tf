locals {
  cluster_tag = var.cluster_tag != "" ? var.cluster_tag : var.cluster_name

  default_tags = {
    "elbv2.k8s.aws/cluster"   = local.cluster_tag
    "${var.tag_prefix}/stack" = var.tag_stack != "" ? var.tag_stack : var.application
  }

  load_balancer_tags = merge(
    length(var.tags) > 0 ? var.tags : merge(local.default_tags, {
      "${var.tag_prefix}/resource" = "LoadBalancer"
    }),
    var.load_balancer_tags,
  )
}
