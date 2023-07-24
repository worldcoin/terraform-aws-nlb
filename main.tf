locals {
  # cluter name without region
  short_cluster_name = replace(var.cluster_name, "-${data.aws_region.current.name}", "")
  name               = join("-", compact([local.short_cluster_name, var.name_suffix]))
  short_name         = substr(local.name, 0, 26) # Shorter name used to bypass 32 char limitation for target groups
  stack              = replace(var.application, "/", ".")
}

resource "aws_security_group" "alb" {
  name        = local.name
  description = "Security group attached to ALB"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = [
      "173.245.48.0/20",
      "103.21.244.0/22",
      "103.22.200.0/22",
      "103.31.4.0/22",
      "141.101.64.0/18",
      "108.162.192.0/18",
      "190.93.240.0/20",
      "188.114.96.0/20",
      "197.234.240.0/22",
      "198.41.128.0/17",
      "162.158.0.0/15",
      "104.16.0.0/13",
      "104.24.0.0/14",
      "172.64.0.0/13",
      "131.0.72.0/22",
    ]
  }
}

resource "aws_lb" "nlb" {
  name                             = substr(local.name, 0, 32) # "name" cannot be longer than 32 characters
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  subnets                          = var.public_subnets
  security_groups                  = [aws_security_group.alb.id]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "ingress.k8s.aws/resource" = "LoadBalancer"
    "ingress.k8s.aws/stack"    = local.stack
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
    "ingress.k8s.aws/resource" = "443"
    "ingress.k8s.aws/stack"    = local.stack
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
    "ingress.k8s.aws/resource" = "80"
    "ingress.k8s.aws/stack"    = local.stack
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_target_group" "tls" {
  name     = "${local.short_name}-tls"
  port     = 30443
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "ingress.k8s.aws/resource" = "${var.application}-traefik:443"
    "ingress.k8s.aws/stack"    = local.stack
  }

  stickiness {
    cookie_duration = 14400
    enabled         = false
    type            = "lb_cookie"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_target_group" "plain" {
  name     = "${local.short_name}-plain"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "ingress.k8s.aws/resource" = "${var.application}-traefik:80"
    "ingress.k8s.aws/stack"    = local.stack
  }

  stickiness {
    cookie_duration = 14400
    enabled         = false
    type            = "lb_cookie"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}
