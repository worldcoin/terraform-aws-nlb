mock_provider "aws" {
  source = "./tests/mocks/aws"
}

variables {
  internal = true
}

run "default_keeps_aws_behaviour" {
  command = plan

  assert {
    condition     = aws_lb.nlb.enforce_security_group_inbound_rules_on_private_link_traffic == null
    error_message = "the NLB must not set the PrivateLink enforcement attribute unless asked to"
  }
}

run "off_is_passed_through" {
  command = plan

  variables {
    enforce_security_group_inbound_rules_on_private_link_traffic = "off"
  }

  assert {
    condition     = aws_lb.nlb.enforce_security_group_inbound_rules_on_private_link_traffic == "off"
    error_message = "the NLB must disable security group enforcement on PrivateLink traffic when asked to"
  }
}

run "rejects_invalid_values" {
  command = plan

  variables {
    enforce_security_group_inbound_rules_on_private_link_traffic = "maybe"
  }

  expect_failures = [var.enforce_security_group_inbound_rules_on_private_link_traffic]
}
