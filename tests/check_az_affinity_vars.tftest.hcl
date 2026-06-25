# Verifies the wiring between the two AZ-affinity variables and the
# `aws_lb.nlb` resource attributes, plus the routing-policy validation.
# Offline-only — uses the mock provider.

mock_provider "aws" {
  source = "./tests/mocks/aws"
}

variables {
  internal = false
}

run "defaults" {
  command = plan

  assert {
    condition     = aws_lb.nlb.enable_cross_zone_load_balancing == true
    error_message = "enable_cross_zone_load_balancing should default to true"
  }

  assert {
    condition     = aws_lb.nlb.dns_record_client_routing_policy == "any_availability_zone"
    error_message = "dns_record_client_routing_policy should default to any_availability_zone"
  }
}

run "overrides" {
  command = plan

  variables {
    enable_cross_zone_load_balancing = false
    dns_record_client_routing_policy = "availability_zone_affinity"
  }

  assert {
    condition     = aws_lb.nlb.enable_cross_zone_load_balancing == false
    error_message = "enable_cross_zone_load_balancing override not propagated to aws_lb"
  }

  assert {
    condition     = aws_lb.nlb.dns_record_client_routing_policy == "availability_zone_affinity"
    error_message = "dns_record_client_routing_policy override not propagated to aws_lb"
  }
}

run "invalid_policy_rejected" {
  command = plan

  variables {
    dns_record_client_routing_policy = "foo"
  }

  expect_failures = [
    var.dns_record_client_routing_policy,
  ]
}
