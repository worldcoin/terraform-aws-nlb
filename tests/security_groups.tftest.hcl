mock_provider "aws" {
  source = "./tests/mocks/aws"
}

variables {
  internal                 = true
  create_default_listeners = false
}

run "default_creates_managed_group" {
  command = plan

  assert {
    condition     = length(aws_security_group.nlb) == 1 && length(aws_lb.nlb.security_groups) == 1
    error_message = "The default must retain one module-created NLB security group."
  }

  assert {
    condition     = output.sg_egress_rules == aws_security_group.nlb[0].egress
    error_message = "Existing callers must retain the managed group's egress output."
  }
}

run "null_inputs_keep_defaults" {
  command = plan

  variables {
    create_security_group = null
    security_group_ids    = null
  }

  assert {
    condition     = length(aws_security_group.nlb) == 1 && length(aws_lb.nlb.security_groups) == 1
    error_message = "Null inputs must preserve the default managed security group."
  }
}

run "existing_groups_without_managed_group" {
  command = plan

  variables {
    create_security_group = false
    security_group_ids    = ["sg-1234abcd", "sg-00000000000000002"]
  }

  assert {
    condition     = length(aws_security_group.nlb) == 0 && aws_lb.nlb.security_groups == toset(var.security_group_ids)
    error_message = "Existing-group mode must attach the supplied groups without creating another group."
  }

  assert {
    condition     = output.sg_nlb_id == null && output.sg_egress_rules == null
    error_message = "Managed-group outputs must be null when no group is created."
  }
}

run "existing_groups_supplement_managed_group" {
  command = plan

  variables {
    security_group_ids = ["sg-00000000000000001"]
  }

  assert {
    condition     = length(aws_security_group.nlb) == 1 && contains(aws_lb.nlb.security_groups, "sg-00000000000000001")
    error_message = "Supplying an existing group must preserve managed-group creation by default."
  }
}

run "rejects_disabled_creation_without_existing_groups" {
  command = plan

  variables {
    create_security_group = false
  }

  expect_failures = [aws_lb.nlb]
}

run "rejects_disabled_creation_with_null_existing_groups" {
  command = plan

  variables {
    create_security_group = false
    security_group_ids    = null
  }

  expect_failures = [aws_lb.nlb]
}

run "rejects_null_group_entry" {
  command = plan

  variables {
    security_group_ids = [null]
  }

  expect_failures = [var.security_group_ids]
}

run "rejects_invalid_group_id" {
  command = plan

  variables {
    security_group_ids = ["not-a-security-group"]
  }

  expect_failures = [var.security_group_ids]
}

run "rejects_non_hexadecimal_group_id" {
  command = plan

  variables {
    security_group_ids = ["sg-zzzzzzzz"]
  }

  expect_failures = [var.security_group_ids]
}

run "rejects_incorrect_group_id_length" {
  command = plan

  variables {
    security_group_ids = ["sg-abc"]
  }

  expect_failures = [var.security_group_ids]
}
