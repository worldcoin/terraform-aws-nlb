resource "aws_lb_listener" "extra" {
  for_each = { for v in var.extra_listeners : v.name => v }

  load_balancer_arn = aws_lb.nlb.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.extra[each.value.name].arn
  }

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "service.k8s.aws/resource" = each.value.port
    "service.k8s.aws/stack"    = var.application
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_target_group" "extra" {
  for_each = { for v in var.extra_listeners : v.name => v }

  name = format("%s-%s", local.short_name, each.value.name)

  port     = each.value.target_group_port
  protocol = each.value.protocol
  vpc_id   = var.vpc_id

  target_type = "ip"

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "service.k8s.aws/resource" = format("%s:%s", var.application, each.value.port)
    "service.k8s.aws/stack"    = var.application
  }

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    port                = "traffic-port"
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
