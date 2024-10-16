# Mock (offline) provider
mock_provider "aws" {
  source = "./tests/mocks/aws" # Path to the directory containing the mock files
}

variables {
  internal = true
  # Override variables from terraform.tfvars here
}

run "check_internal_nlb" {
  command = plan

  assert {
    condition     = var.internal == true && var.private_subnets != []
    error_message = "internal NLB requires private subnets"
  }
}
