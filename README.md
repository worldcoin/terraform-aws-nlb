# terraform-aws-nlb

The module code moved from https://github.com/worldcoin/infrastructure/tree/main/modules/clusters/orb/nlb

## Example
```terraform
module "nlb" {
  source = "github.com/worldcoin/terraform-aws-nlb?ref=v0.1.0"

  cluster_name = var.name
  application  = "traefik/traefik"
  internal     = false

  acm_arn        = var.acm_arn
  acm_extra_arns = var.acm_extra_arns
  vpc_id         = var.vpc_config.vpc_id
  public_subnets = var.vpc_config.public_subnets
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.nlb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.plain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_target_group.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.plain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_arn"></a> [acm\_arn](#input\_acm\_arn) | ARN for ACM certificate used for TLS | `string` | n/a | yes |
| <a name="input_acm_extra_arns"></a> [acm\_extra\_arns](#input\_acm\_extra\_arns) | ARNs of ACM certificates used for TLS, attached as additional certificates to the main NLB | `list(string)` | `[]` | no |
| <a name="input_application"></a> [application](#input\_application) | (namespace/app) - Name of application which will be connected to this NLB | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster will be used as suffix to all resources | `string` | n/a | yes |
| <a name="input_extra_listeners"></a> [extra\_listeners](#input\_extra\_listeners) | List with configuration for additional listeners | <pre>list(object({<br>    name              = string<br>    port              = string<br>    protocol          = optional(string, "TCP")<br>    target_group_port = number<br>  }))</pre> | `[]` | no |
| <a name="input_health_check_port"></a> [health\_check\_port](#input\_health\_check\_port) | Port used for health check for listener | `string` | `"traffic-port"` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Set NLB to be internal (available only within VPC) | `bool` | n/a | yes |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Part of the name used to differentiate NLBs for multiple traefik instances | `string` | `""` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | List of public subnets to use | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the NLB will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the NLB. |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name of the NLB. |
| <a name="output_ready"></a> [ready](#output\_ready) | Hack! Because modules with providers (cluster-apps) cannot use depends\_on output value needs to be used to make sure those are provisioned in correct order. |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The zone ID of the NLB. |
<!-- END_TF_DOCS -->
