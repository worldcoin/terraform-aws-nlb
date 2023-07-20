locals {
  # cluter name without region
  short_cluster_name = replace(var.cluster_name, "-${data.aws_region.current.name}", "")
  name               = join("-", compact([local.short_cluster_name, var.name_suffix]))
  short_name         = substr(local.name, 0, 26) # Shorter name used to bypass 32 char limitation for target groups
}

resource "aws_lb" "nlb" {
  name                             = substr(local.name, 0, 32) # "name" cannot be longer than 32 characters
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  subnets                          = var.public_subnets
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "service.k8s.aws/resource" = "LoadBalancer"
    "service.k8s.aws/stack"    = var.application
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_listener" "tls" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.acm_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tls.arn
  }

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "service.k8s.aws/resource" = "443"
    "service.k8s.aws/stack"    = var.application
  }

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
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.plain.arn
  }

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "service.k8s.aws/resource" = "80"
    "service.k8s.aws/stack"    = var.application
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_target_group" "tls" {
  name     = "${local.short_name}-tls"
  port     = 60443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  target_type = "ip"

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "service.k8s.aws/resource" = "${var.application}:443"
    "service.k8s.aws/stack"    = var.application
  }

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    port                = "9000"
    protocol            = "HTTP"
    unhealthy_threshold = 3
  }

  stickiness {
    cookie_duration = 0
    enabled         = false
    type            = "lb_cookie"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_target_group" "plain" {
  name     = "${local.short_name}-plain"
  port     = 60080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "service.k8s.aws/resource" = "${var.application}:80"
    "service.k8s.aws/stack"    = var.application
  }

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    port                = "9000"
    protocol            = "HTTP"
    unhealthy_threshold = 3
  }

  stickiness {
    cookie_duration = 0
    enabled         = false
    type            = "lb_cookie"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}
