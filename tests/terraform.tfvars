acm_arn = "arn:aws:acm:ap-south-1:123412341234:certificate/aabbcc11-1312-abcd-qwer-1a2s3d4f5g6h"
acm_extra_arns = [
  "arn:aws:acm:ap-south-1:123412341234:certificate/aabbcc22-1312-abcd-qwer-1a2s3d4f5g6h",
  "arn:aws:acm:ap-south-1:123412341234:certificate/aabbcc33-1312-abcd-qwer-1a2s3d4f5g6h"
]
application                = "namespace/app"
cluster_name               = "some-cluster"
enable_deletion_protection = "true"
extra_listeners = [
  {
    name              = "foo"
    port              = 443
    target_group_port = 80
  },
]
health_check_port = "80"
ingress_sg_rules = [
  {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow http from anywhere"
    port        = 80
  },
  {
    ipv6_cidr_blocks = ["::/0"]
    description      = "allow http from anywhere"
    port             = 80
  },
  {
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow https from anywhere"
    port        = 443
  },
  {
    ipv6_cidr_blocks = ["::/0"]
    description      = "allow https from anywhere"
    port             = 443
  },
]
internal = fasle
name     = "nlb"
private_subnets = [
  "subnet-2f2f2f2f2f2f2f2f",
  "subnet-3f3f3f3f3f3f3f3f"
]
public_subnets = [
  "subnet-2p2p2p2p2p2p2p2p",
  "subnet-3p3p3p3p3p3p3p3p"
]
tls_listener_version = "1.3"
vpc_id               = "vpc-0a0a0a0a0a0a0a0a0"
