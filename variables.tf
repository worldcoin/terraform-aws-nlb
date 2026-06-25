variable "cluster_name" {
  description = "Name of the cluster will be used as suffix to all resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must be lowercase alphanumeric characters or hyphens"
  }
}

variable "name" {
  description = "Name of the NLB, overrides default naming"
  type        = string
  default     = ""
  validation {
    condition     = var.name == "" ? true : can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Name must be lowercase alphanumeric characters or hyphens"
  }
}

variable "application" {
  description = "(namespace/app) - Name of application which will be connected to this NLB"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-\\/a-z0-9-]+$", var.application))
    error_message = "Application name must be lowercase alphanumeric characters or hyphens"
  }
}

variable "acm_arn" {
  description = "ARN for ACM certificate used for TLS. Required when the default TLS listener is enabled."
  type        = string
  default     = null
  validation {
    condition     = var.acm_arn == null || can(regex("^arn:aws:acm:[a-z][a-z]-[a-z]+-[1-9]:\\d{12}:certificate/[A-Za-z0-9\\-]+$", var.acm_arn))
    error_message = "Invalid ACM ARN"
  }
}

variable "acm_extra_arns" {
  description = "ARNs of ACM certificates used for TLS, attached as additional certificates to the main NLB"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for arn in var.acm_extra_arns : can(regex("arn:aws:acm:[a-z][a-z]-[a-z]+-[1-9]:\\d{12}:certificate/[A-Za-z0-9\\-]+$", arn))])
    error_message = "Invalid ACM ARN"
  }
}

variable "vpc_id" {
  description = "VPC ID where the NLB will be deployed"
  type        = string
  validation {
    condition     = can(regex("vpc-[a-z0-9]+", var.vpc_id))
    error_message = "Invalid VPC ID"
  }
}

variable "public_subnets" {
  description = "List of public subnets to use"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for subnet in var.public_subnets : can(regex("subnet-[a-z0-9]+", subnet))])
    error_message = "Invalid subnet ID"
  }
}

variable "private_subnets" {
  description = "List of private subnets to use"
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for subnet in var.private_subnets : can(regex("subnet-[a-z0-9]+", subnet))])
    error_message = "Invalid subnet ID"
  }
}

variable "name_suffix" {
  description = "Part of the name used to differentiate NLBs for multiple traefik instances"
  type        = string
  default     = ""
  validation {
    condition     = var.name_suffix == "" ? true : can(regex("^[a-z0-9-]+$", var.name_suffix))
    error_message = "Name suffix must be lowercase alphanumeric characters or hyphens"
  }
}

variable "internal" {
  description = "Set NLB to be internal (available only within VPC)"
  type        = bool
}

variable "create_default_listeners" {
  description = "If true, default listeners will be created"
  type        = bool
  default     = true
}

variable "create_default_plain_listener" {
  description = "If true, default listener (80) will be created (ANDed with create_default_listeners)"
  type        = bool
  default     = true
}

variable "create_default_tls_listener" {
  description = "If true, tls listener (443) will be created (ANDed with create_default_listeners)"
  type        = bool
  default     = true
}

variable "extra_listeners" {
  description = "List with configuration for additional listeners"
  type = list(object({
    name              = string
    port              = string
    protocol          = optional(string, "TCP")
    target_group_port = number
  }))

  default = []
  validation {
    condition = alltrue([
      for listener in var.extra_listeners : (
        can(regex("^[a-z0-9-]+$", listener.name)) &&
        can(regex("^[0-9]+$", listener.port)) &&
        can(regex("^[0-9]+$", listener.target_group_port)) &&
        (listener.protocol == "TCP" || listener.protocol == "UDP" || listener.protocol == "TCP_UDP" || listener.protocol == "TLS")
    )])
    error_message = "Listener name must be lowercase alphanumeric characters"
  }
}

variable "health_check_port" {
  description = "Port used for health check for listener"
  type        = number
  default     = -1
  validation {
    condition     = var.health_check_port == -1 || (var.health_check_port >= 0 && var.health_check_port <= 65535)
    error_message = "Health check port must be between 0 and 65535"
  }
}

variable "tls_listener_version" {
  description = "Minimum TLS version served by TLS listener"
  type        = string
  default     = "1.3"
  validation {
    condition     = var.tls_listener_version == "1.2" || var.tls_listener_version == "1.3"
    error_message = "Only TLS >= 1.2 or 1.3 are supported"
  }
}
variable "ingress_sg_rules" {
  description = "The security group rules to allow ingress from."
  type = set(object({
    description      = optional(string, "")
    protocol         = optional(string, "tcp")
    port             = optional(number, 443)
    security_groups  = optional(list(string))
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
  }))
  default = [
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
  validation {
    condition = alltrue([
      for rule in var.ingress_sg_rules : (
        rule.description != null ? can(regex("\\s\\w*", rule.description)) : true &&
        rule.protocol != null ? can(regex("^[a-z]+$", rule.protocol)) : true &&
        rule.port != null ? (rule.port >= 1 && rule.port <= 65535) : true &&
        rule.security_groups != null ? alltrue([for sg in rule.security_groups : can(regex("sg-[a-z0-9]+", sg))]) : true &&
        rule.cidr_blocks != null ? alltrue([for cidr in rule.cidr_blocks : can(cidrnetmask(cidr))]) : true &&
        rule.ipv6_cidr_blocks != null ? alltrue([for cidr in rule.ipv6_cidr_blocks : can(cidrnetmask(cidr))]) : true
      )
    ])
    error_message = "Invalid security group rule"
  }
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing is enabled (NLB routes to targets in any AZ regardless of which AZ the LB node received the traffic on). Disabling can reduce cross-AZ data-transfer charges, but the NLB node in a given AZ will drop traffic when no healthy targets exist in that AZ. Defaults to true to preserve prior behavior."
  type        = bool
  default     = true
}

variable "dns_record_client_routing_policy" {
  description = "DNS client routing policy controlling which AZ's NLB node IP Route 53 returns when a client resolves the NLB hostname. `any_availability_zone` (default) returns IPs from any AZ. `partial_availability_zone_affinity` returns the local-AZ IP for ~85% of clients. `availability_zone_affinity` returns the local-AZ IP for 100% of clients. Combine with `enable_cross_zone_load_balancing = false` for end-to-end AZ affinity (client → NLB node → target all in same AZ), eliminating cross-AZ data-transfer cost. Caller must ensure each AZ has ≥1 healthy target; otherwise local-AZ clients will see failures rather than fail over."
  type        = string
  default     = "any_availability_zone"
  validation {
    condition     = contains(["any_availability_zone", "partial_availability_zone_affinity", "availability_zone_affinity"], var.dns_record_client_routing_policy)
    error_message = "dns_record_client_routing_policy must be one of: any_availability_zone, partial_availability_zone_affinity, availability_zone_affinity"
  }
}

variable "tag_prefix" {
  description = "Tag key prefix for LBC resource/stack tags (e.g. service.k8s.aws for Service LB, gateway.k8s.aws.nlb for Gateway API)"
  type        = string
  default     = "service.k8s.aws"
}

variable "tag_stack" {
  description = "Override the computed stack tag value (default: var.application)"
  type        = string
  default     = ""
}

variable "cluster_tag" {
  description = "Value for the elbv2.k8s.aws/cluster tag. Defaults to cluster_name. Use when the tag must differ from the name used to construct the LB name (e.g. Gateway API where the LB name prefix is trimmed but the tag must match the LBC --cluster-name)."
  type        = string
  default     = ""
}
