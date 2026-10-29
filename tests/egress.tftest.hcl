mock_provider "aws" {
  source = "./tests/mocks/aws"
}

variables {
  cluster_name             = "rehearsal-test"
  application              = "rehearsal/transport"
  vpc_id                   = "vpc-0123456789abcdef0"
  private_subnets          = ["subnet-0123456789abcdef0"]
  internal                 = true
  create_default_listeners = false
}

run "default_allows_vpc_ports_and_associated_cidrs" {
  command = plan

  assert {
    condition = jsonencode(aws_security_group.nlb.egress) == jsonencode([{
      description      = "Allow backend and health-check traffic within the VPC"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      cidr_blocks      = ["10.0.0.0/16", "10.1.0.0/16"]
      ipv6_cidr_blocks = []
      security_groups  = []
      prefix_list_ids  = []
      self             = false
    }])
    error_message = "Default egress must allow all VPC target ports, include associated IPv4 ranges and exclude disassociating ranges."
  }
}

run "null_uses_vpc_default" {
  command = plan

  variables {
    egress_sg_rules = null
  }

  assert {
    condition     = length(aws_security_group.nlb.egress) == 1 && one(aws_security_group.nlb.egress).protocol == "-1" && toset(one(aws_security_group.nlb.egress).cidr_blocks) == toset(["10.0.0.0/16", "10.1.0.0/16"])
    error_message = "An explicit null must inherit the VPC-scoped default."
  }
}

run "empty_manages_no_outbound_rules" {
  command = plan

  variables {
    egress_sg_rules = []
  }

  assert {
    condition     = length(aws_security_group.nlb.egress) == 0
    error_message = "An explicit empty collection must clear outbound rules."
  }
}

run "restricted_target_and_health_check_ports" {
  command = plan

  variables {
    egress_sg_rules = [for port in [50050, 8545] : {
      description     = "Rehearsal target and health check"
      protocol        = "tcp"
      from_port       = port
      to_port         = port
      security_groups = ["sg-0123456789abcdef0"]
    }]
  }

  assert {
    condition = length(aws_security_group.nlb.egress) == 2 && alltrue([
      for rule in aws_security_group.nlb.egress : (
        rule.protocol == "tcp" && rule.from_port == rule.to_port &&
        contains([50050, 8545], rule.to_port) &&
        rule.security_groups == toset(["sg-0123456789abcdef0"]) &&
        length(rule.cidr_blocks) == 0 && length(rule.ipv6_cidr_blocks) == 0
      )
    ])
    error_message = "Restricted rules must replace, not supplement, unrestricted egress."
  }
}

run "rejects_missing_destination" {
  command = plan

  variables {
    egress_sg_rules = [{ protocol = "tcp", from_port = 50050, to_port = 50050 }]
  }

  expect_failures = [var.egress_sg_rules]
}

run "rejects_null_rule" {
  command = plan

  variables {
    egress_sg_rules = [null]
  }

  expect_failures = [var.egress_sg_rules]
}
