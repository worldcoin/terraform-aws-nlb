mock_provider "aws" {
  source = "./tests/mocks/aws"
}

variables {
  internal                 = true
  create_default_listeners = false
  tags                     = { owner = "ecs" }
  target_groups = {
    ep-api = {
      port                 = 8080
      deregistration_delay = 60
      health_check = {
        protocol            = "HTTP"
        path                = "/health"
        matcher             = "200"
        interval            = 30
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }
  listeners = {
    http = {
      port             = 80
      target_group_key = "ep-api"
    }
  }
}

run "ecs_listener_and_target_group" {
  command = plan

  assert {
    condition     = aws_lb_target_group.this["ep-api"].deregistration_delay == "60" && aws_lb_target_group.this["ep-api"].health_check[0].protocol == "HTTP" && aws_lb_target_group.this["ep-api"].health_check[0].path == "/health"
    error_message = "Target group must preserve ECS draining and HTTP health-check settings."
  }

  assert {
    condition     = aws_lb_listener.this["http"].port == 80 && aws_lb_listener.this["http"].default_action[0].type == "forward"
    error_message = "Listener must forward to the requested target group."
  }
}
