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
  subnets                          = var.private_subnets != null ? var.private_subnets : var.public_subnets
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = var.enable_deletion_protection

  tags = merge(local.default_tags, {
    "service.k8s.aws/resource" = "LoadBalancer"
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
  count = var.add_default_listeners ? 1 : 0

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

  #tfsec:ignore:aws-vpc-no-public-egress-sgr
  egress {
    description = "Allow all for egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener_certificate" "extra" {
  count           = var.add_default_listeners ? length(var.acm_extra_arns) : 0
  listener_arn    = aws_lb_listener.tls.arn
  certificate_arn = element(var.acm_extra_arns, count.index)
}

moved {
  from = aws_lb_listener.plan
  to   = aws_lb_listener.plain[0]
}

resource "aws_lb_listener" "plain" {
  count = var.add_default_listeners ? 1 : 0

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
