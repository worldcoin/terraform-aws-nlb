# Mock (offline) provider
mock_provider "aws" {
  source = "./tests/mocks/aws" # Path to the directory containing the mock files
}

variables {
  internal = false
  # Override variables from terraform.tfvars here
}

run "check_external_nlb" {
  command = plan

  assert {
    condition     = var.internal == false && var.public_subnets != []
    error_message = "External NLB requires public subnets"
  }
}
