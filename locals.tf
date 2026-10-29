locals {
  cluster_tag = var.cluster_tag != "" ? var.cluster_tag : var.cluster_name

  # VPC-wide egress lets new target and health-check ports work without SG edits.
  default_egress_sg_rules = [{
    description = "Allow backend and health-check traffic within the VPC"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = sort(distinct(concat(
      [data.aws_vpc.current.cidr_block],
      [for association in data.aws_vpc.current.cidr_block_associations : association.cidr_block if association.state == "associated"],
    )))
    ipv6_cidr_blocks = []
    security_groups  = []
  }]

  egress_sg_rules = var.egress_sg_rules == null ? local.default_egress_sg_rules : var.egress_sg_rules

  default_tags = {
    "elbv2.k8s.aws/cluster"   = local.cluster_tag
    "${var.tag_prefix}/stack" = var.tag_stack != "" ? var.tag_stack : var.application
  }
}
