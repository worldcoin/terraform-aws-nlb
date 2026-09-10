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

run "dynamic_ecs_listener_and_target_group" {
  command = plan

  assert {
    condition     = aws_lb_target_group.dynamic["ep-api"].deregistration_delay == "60" && aws_lb_target_group.dynamic["ep-api"].health_check[0].protocol == "HTTP" && aws_lb_target_group.dynamic["ep-api"].health_check[0].path == "/health"
    error_message = "Dynamic target group must preserve ECS draining and HTTP health-check settings."
  }

  assert {
    condition     = aws_lb_listener.dynamic["http"].port == 80 && aws_lb_listener.dynamic["http"].default_action[0].type == "forward"
    error_message = "Dynamic listener must forward to the requested dynamic target group."
  }
}
