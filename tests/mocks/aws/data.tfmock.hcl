mock_data "aws_partition" {
  defaults = {
    partition  = "aws"
    dns_suffix = "amazonaws.com"
  }
}

mock_data "aws_vpc" {
  defaults = {
    cidr_block = "10.0.0.0/16"
    cidr_block_associations = [
      { association_id = "vpc-cidr-assoc-11111111111111111", cidr_block = "10.0.0.0/16", state = "associated" },
      { association_id = "vpc-cidr-assoc-22222222222222222", cidr_block = "10.1.0.0/16", state = "associated" },
      { association_id = "vpc-cidr-assoc-33333333333333333", cidr_block = "10.2.0.0/16", state = "disassociating" },
    ]
  }
}
