# Mock (offline) provider
mock_provider "aws" {
  source = "./tests/mocks/aws" # Path to the directory containing the mock files
}

variables {
  internal = false
}

run "default_tags" {
  command = plan

  assert {
    condition     = aws_lb.nlb.tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "Default elbv2.k8s.aws/cluster tag should equal cluster_name when var.tags is empty"
  }

  assert {
    condition     = aws_lb.nlb.tags["service.k8s.aws/resource"] == "LoadBalancer"
    error_message = "Default resource tag missing from NLB tags"
  }

  assert {
    condition     = aws_lb.nlb.tags["service.k8s.aws/stack"] == var.application
    error_message = "Default stack tag missing from NLB tags"
  }

  assert {
    condition     = aws_lb_listener.tls[0].tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "TLS listener should carry the same default cluster tag as the NLB"
  }

  assert {
    condition     = aws_lb_target_group.tls[0].tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "TLS target group should carry the same default cluster tag as the NLB"
  }
}

run "tags_fully_replace_defaults" {
  command = plan

  variables {
    tags = {
      Team = "infrastructure"
    }
  }

  assert {
    condition     = aws_lb.nlb.tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on the NLB, not merge with them"
  }

  assert {
    condition     = aws_lb_listener.tls[0].tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on the TLS listener, not merge with them"
  }

  assert {
    condition     = aws_lb_listener.plain[0].tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on the plain listener, not merge with them"
  }

  assert {
    condition     = aws_lb_target_group.tls[0].tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on the TLS target group, not merge with them"
  }

  assert {
    condition     = aws_lb_target_group.plain[0].tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on the plain target group, not merge with them"
  }
}

run "tags_fully_replace_defaults_on_extra_listener" {
  command = plan

  variables {
    tags = {
      Team = "infrastructure"
    }
    extra_listeners = [
      {
        name              = "foo"
        port              = 8443
        target_group_port = 8080
      },
    ]
  }

  assert {
    condition     = aws_lb_listener.extra["foo"].tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on an extra listener, not merge with them"
  }

  assert {
    condition     = aws_lb_target_group.extra["foo"].tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on an extra target group, not merge with them"
  }
}

run "null_tags_falls_back_to_defaults" {
  command = plan

  variables {
    tags = null
  }

  assert {
    condition     = aws_lb.nlb.tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "var.tags = null should behave like the {} default (nullable = false), not error or omit defaults"
  }
}

run "cluster_tag_variable_still_feeds_the_default" {
  command = plan

  variables {
    cluster_tag = "custom-cluster-tag"
  }

  assert {
    condition     = aws_lb.nlb.tags["elbv2.k8s.aws/cluster"] == "custom-cluster-tag"
    error_message = "var.cluster_tag should still set the default elbv2.k8s.aws/cluster value when var.tags is empty"
  }
}
