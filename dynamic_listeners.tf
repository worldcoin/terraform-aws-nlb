resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = format("%s-%s", local.short_name, each.key)
  port                 = each.value.port
  protocol             = each.value.protocol
  target_type          = each.value.target_type
  vpc_id               = var.vpc_id
  deregistration_delay = each.value.deregistration_delay

  health_check {
    enabled             = each.value.health_check.enabled
    healthy_threshold   = each.value.health_check.healthy_threshold
    interval            = each.value.health_check.interval
    matcher             = each.value.health_check.matcher
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    timeout             = each.value.health_check.timeout
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
  }

  tags = merge(
    length(var.tags) > 0 ? var.tags : local.default_tags,
    each.value.tags,
  )

  lifecycle {
    precondition {
      condition     = length(format("%s-%s", local.short_name, each.key)) <= 32
      error_message = "The NLB name prefix and dynamic target group key together must be at most 32 characters."
    }

    precondition {
      condition = (
        !(var.create_default_listeners && var.create_default_tls_listener && each.key == "tls") &&
        !(var.create_default_listeners && var.create_default_plain_listener && each.key == "plain") &&
        !contains([for listener in var.extra_listeners : listener.name], each.key)
      )
      error_message = "A dynamic target group key must not conflict with an enabled legacy target group."
    }

    precondition {
      condition     = !contains(["UDP", "TCP_UDP"], each.value.protocol) || each.value.health_check.protocol == "TCP"
      error_message = "UDP and TCP_UDP target groups require TCP health checks."
    }

    precondition {
      condition     = each.value.target_type != "alb" || each.value.port == 80 || each.value.port == 443
      error_message = "ALB target groups require port 80 or 443."
    }

    ignore_changes = [tags_all]
  }
}

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.nlb.arn
  port              = each.value.port
  protocol          = each.value.protocol
  certificate_arn   = each.value.certificate_arn
  ssl_policy        = each.value.ssl_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dynamic[each.value.target_group_key].arn
  }

  tags = merge(
    length(var.tags) > 0 ? var.tags : local.default_tags,
    each.value.tags,
  )

  lifecycle {
    precondition {
      condition = (
        !(var.create_default_listeners && var.create_default_tls_listener && each.value.port == 443) &&
        !(var.create_default_listeners && var.create_default_plain_listener && each.value.port == 80) &&
        !contains([for listener in var.extra_listeners : tonumber(listener.port)], each.value.port)
      )
      error_message = "A dynamic listener port must not conflict with an enabled legacy listener."
    }

    precondition {
      condition     = contains(keys(var.target_groups), each.value.target_group_key)
      error_message = "Each listener target_group_key must exist in var.target_groups."
    }

    ignore_changes = [tags_all]
  }
}
