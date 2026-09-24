locals {
  # cluter name without region
  short_cluster_name = replace(var.cluster_name, "-${data.aws_region.current.region}", "")
  name               = var.name == "" ? join("-", compact([local.short_cluster_name, var.name_suffix])) : var.name
  short_name         = substr(local.name, 0, 26) # Shorter name used to bypass 32 char limitation for target groups
}

#trivy:ignore:aws-elb-alb-not-public
resource "aws_lb" "nlb" {
  name                             = trimsuffix(substr(local.name, 0, 32), "-") # "name" cannot be longer than 32 characters and cannot end with "-"
  internal                         = var.internal
  load_balancer_type               = "network"
  subnets                          = length(var.private_subnets) > 0 ? var.private_subnets : var.public_subnets
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  dns_record_client_routing_policy = var.dns_record_client_routing_policy
  enable_deletion_protection       = var.enable_deletion_protection

  enforce_security_group_inbound_rules_on_private_link_traffic = var.enforce_security_group_inbound_rules_on_private_link_traffic

  # var.tags fully replaces (not merges with) local.default_tags, so a non-cluster
  # NLB can drop elbv2.k8s.aws/cluster entirely instead of just blanking it.
  tags = length(var.tags) > 0 ? var.tags : merge(local.default_tags, {
    "${var.tag_prefix}/resource" = "LoadBalancer"
  })

  security_groups = [aws_security_group.nlb.id]

  lifecycle {
    ignore_changes = [
      tags_all,
      security_groups, # changing security groups forces recreation, and we don't want it
    ]
  }
}

moved {
  from = aws_lb_listener.tls
  to   = aws_lb_listener.tls[0]
}
resource "aws_lb_listener" "tls" {
  count = var.create_default_listeners && var.create_default_tls_listener ? 1 : 0

  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = var.acm_arn

  ssl_policy = var.tls_listener_version == "1.3" ? "ELBSecurityPolicy-TLS13-1-3-2021-06" : "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tls[0].arn
  }

  # Same full-replace semantics as aws_lb.nlb.tags above.
  tags = length(var.tags) > 0 ? var.tags : merge(local.default_tags, {
    "${var.tag_prefix}/resource" = "443"
  })

  lifecycle {
    precondition {
      condition     = var.acm_arn != null
      error_message = "acm_arn is required when the default TLS listener is enabled."
    }
    ignore_changes = [tags_all]
  }
}

resource "aws_security_group" "nlb" {
  name        = substr(local.name, 0, 32)
  description = format("SG for %s", local.name)
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_sg_rules

    content {
      description      = ingress.value["description"]
      from_port        = ingress.value["port"]
      to_port          = ingress.value["port"]
      protocol         = ingress.value["protocol"]
      security_groups  = ingress.value["security_groups"]
      cidr_blocks      = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
    }
  }

  # Attribute syntax ensures [] removes existing rules instead of leaving them unmanaged.
  #trivy:ignore:aws-vpc-no-public-egress-sgr
  egress = [for rule in var.egress_sg_rules : {
    description      = rule.description
    from_port        = rule.from_port
    to_port          = rule.to_port
    protocol         = rule.protocol
    security_groups  = rule.security_groups
    cidr_blocks      = rule.cidr_blocks
    ipv6_cidr_blocks = rule.ipv6_cidr_blocks
    prefix_list_ids  = []
    self             = false
  }]
}

resource "aws_lb_listener_certificate" "extra" {
  count           = var.create_default_listeners && var.create_default_tls_listener ? length(var.acm_extra_arns) : 0
  listener_arn    = aws_lb_listener.tls[0].arn
  certificate_arn = element(var.acm_extra_arns, count.index)
}

moved {
  from = aws_lb_listener.plain
  to   = aws_lb_listener.plain[0]
}

resource "aws_lb_listener" "plain" {
  count = var.create_default_listeners && var.create_default_plain_listener ? 1 : 0

  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.plain[0].arn
  }

  # Same full-replace semantics as aws_lb.nlb.tags above.
  tags = length(var.tags) > 0 ? var.tags : merge(local.default_tags, {
    "${var.tag_prefix}/resource" = "80"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

moved {
  from = aws_lb_target_group.tls
  to   = aws_lb_target_group.tls[0]
}
resource "aws_lb_target_group" "tls" {
  count = var.create_default_listeners && var.create_default_tls_listener ? 1 : 0

  name     = "${local.short_name}-tls"
  port     = 60443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  # Same full-replace semantics as aws_lb.nlb.tags above.
  tags = length(var.tags) > 0 ? var.tags : merge(local.default_tags, {
    "${var.tag_prefix}/resource" = "${var.application}:443"
  })

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    port                = var.health_check_port == -1 ? "traffic-port" : var.health_check_port
    protocol            = "TCP"
    unhealthy_threshold = 3
  }

  stickiness {
    cookie_duration = 0
    enabled         = false
    type            = "source_ip"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

moved {
  from = aws_lb_target_group.plain
  to   = aws_lb_target_group.plain[0]
}
resource "aws_lb_target_group" "plain" {
  count = var.create_default_listeners && var.create_default_plain_listener ? 1 : 0

  name     = "${local.short_name}-plain"
  port     = 60080
  protocol = "TCP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  # Same full-replace semantics as aws_lb.nlb.tags above.
  tags = length(var.tags) > 0 ? var.tags : merge(local.default_tags, {
    "${var.tag_prefix}/resource" = "${var.application}:80"
  })

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    port                = var.health_check_port == -1 ? "traffic-port" : var.health_check_port
    protocol            = "TCP"
    unhealthy_threshold = 3
  }

  stickiness {
    cookie_duration = 0
    enabled         = false
    type            = "source_ip"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}
