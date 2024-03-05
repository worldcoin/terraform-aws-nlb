locals {
  # cluter name without region
  short_cluster_name = replace(var.cluster_name, "-${data.aws_region.current.name}", "")
  name               = var.name == "" ? join("-", compact([local.short_cluster_name, var.name_suffix])) : var.name
  short_name         = substr(local.name, 0, 26) # Shorter name used to bypass 32 char limitation for target groups
}

resource "aws_lb" "nlb" {
  name                             = substr(local.name, 0, 32) # "name" cannot be longer than 32 characters
  internal                         = var.internal
  load_balancer_type               = "network"
  subnets                          = var.public_subnets
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  tags = merge(local.default_tags, {
    "service.k8s.aws/resource" = "LoadBalancer"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_listener" "tls" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = var.acm_arn

  ssl_policy = var.tls_listener_version == "1.3" ? "ELBSecurityPolicy-TLS13-1-3-2021-06" : "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tls.arn
  }

  tags = merge(local.default_tags, {
    "service.k8s.aws/resource" = "443"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_listener_certificate" "extra" {
  count           = length(var.acm_extra_arns)
  listener_arn    = aws_lb_listener.tls.arn
  certificate_arn = element(var.acm_extra_arns, count.index)
}

resource "aws_lb_listener" "plain" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.plain.arn
  }

  tags = merge(local.default_tags, {
    "service.k8s.aws/resource" = "80"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_target_group" "tls" {
  name     = "${local.short_name}-tls"
  port     = 60443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  tags = merge(local.default_tags, {
    "service.k8s.aws/resource" = "${var.application}:443"
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

resource "aws_lb_target_group" "plain" {
  name     = "${local.short_name}-plain"
  port     = 60080
  protocol = "TCP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  tags = merge(local.default_tags, {
    "service.k8s.aws/resource" = "${var.application}:80"
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
