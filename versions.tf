terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.22.0" # dns_record_client_routing_policy on aws_lb was added in 5.22.0
    }
  }

  required_version = ">= 1.2"
}
