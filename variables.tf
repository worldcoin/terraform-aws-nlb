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

variable "egress_sg_rules" {
  description = "Replacement outbound rules for the NLB security group. Omitted or null preserves unrestricted IPv4 egress; [] removes all outbound rules. Include target and health-check ports when restricting egress."
  type = set(object({
    description      = optional(string, "")
    protocol         = string
    from_port        = number
    to_port          = number
    security_groups  = optional(list(string), [])
    cidr_blocks      = optional(list(string), [])
    ipv6_cidr_blocks = optional(list(string), [])
  }))
  default = [{
    description = "Allow all for egress"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }]
  nullable = false

  validation {
    condition = alltrue([
      for rule in var.egress_sg_rules : rule == null ? false : (
        length(rule.security_groups) + length(rule.cidr_blocks) + length(rule.ipv6_cidr_blocks) > 0
      )
    ])
    error_message = "Each egress rule must specify at least one security group, IPv4 CIDR or IPv6 CIDR destination."
  }
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API"
  type        = bool
  default     = true
}

variable "enforce_security_group_inbound_rules_on_private_link_traffic" {
  description = "Whether the NLB security group inbound rules are enforced on traffic arriving through AWS PrivateLink (for example API Gateway VPC Links). Valid values are \"on\" and \"off\"; null keeps the AWS default (\"on\")."
  type        = string
  default     = null

  validation {
    condition     = var.enforce_security_group_inbound_rules_on_private_link_traffic == null || contains(["on", "off"], var.enforce_security_group_inbound_rules_on_private_link_traffic)
    error_message = "enforce_security_group_inbound_rules_on_private_link_traffic must be \"on\", \"off\" or null."
  }
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing is enabled (NLB routes to targets in any AZ regardless of which AZ the LB node received the traffic on). Disabling can reduce cross-AZ data-transfer charges, but the NLB node in a given AZ will drop traffic when no healthy targets exist in that AZ. Defaults to true to preserve prior behavior."
  type        = bool
  default     = true
}

variable "target_groups" {
  description = "Additional named target groups for non-controller integrations such as ECS. Keys are stable Terraform identities."
  type = map(object({
    port                 = number
    protocol             = optional(string, "TCP")
    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 300)
    health_check = optional(object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 3)
      interval            = optional(number, 30)
      matcher             = optional(string)
      path                = optional(string)
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "TCP")
      timeout             = optional(number)
      unhealthy_threshold = optional(number, 3)
    }), {})
    tags = optional(map(string), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for name, target_group in var.target_groups : (
        can(regex("^[a-z0-9-]+$", name)) &&
        target_group.port >= 1 && target_group.port <= 65535 &&
        contains(["TCP", "TLS", "UDP", "TCP_UDP"], target_group.protocol) &&
        contains(["instance", "ip", "alb"], target_group.target_type) &&
        target_group.deregistration_delay >= 0 && target_group.deregistration_delay <= 3600 &&
        contains(["TCP", "HTTP", "HTTPS"], target_group.health_check.protocol) &&
        target_group.health_check.interval >= 5 && target_group.health_check.interval <= 300 &&
        target_group.health_check.healthy_threshold >= 2 && target_group.health_check.healthy_threshold <= 10 &&
        target_group.health_check.unhealthy_threshold >= 2 && target_group.health_check.unhealthy_threshold <= 10 &&
        (target_group.health_check.timeout == null || (target_group.health_check.timeout >= 2 && target_group.health_check.timeout <= 120)) &&
        (target_group.health_check.protocol == "TCP" || target_group.health_check.path != null)
      )
    ])
    error_message = "Target group names, ports, protocols, health checks, or deregistration delays are invalid. HTTP(S) health checks require a path."
  }
}

variable "listeners" {
  description = "Additional named listeners. Each listener forwards to a target_groups key; keys are stable Terraform identities."
  type = map(object({
    port             = number
    protocol         = optional(string, "TCP")
    target_group_key = string
    certificate_arn  = optional(string)
    ssl_policy       = optional(string)
    tags             = optional(map(string), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for name, listener in var.listeners : (
        can(regex("^[a-z0-9-]+$", name)) &&
        listener.port >= 1 && listener.port <= 65535 &&
        contains(["TCP", "TLS", "UDP", "TCP_UDP"], listener.protocol) &&
        can(regex("^[a-z0-9-]+$", listener.target_group_key)) &&
        (listener.protocol == "TLS" ? listener.certificate_arn != null : listener.certificate_arn == null)
      )
    ])
    error_message = "Listener names, ports, protocols, target group keys, or TLS certificates are invalid. TLS listeners require certificate_arn; other protocols must not set it."
  }
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

variable "tags" {
  description = "Tags for the NLB and its listeners/target groups (default, extra, and Gateway API). If non-empty, these fully replace the module's default tags (`elbv2.k8s.aws/cluster`, `<tag_prefix>/resource`, `<tag_prefix>/stack`) instead of merging with them - use this for an NLB that must not be tracked/managed by an EKS AWS Load Balancer Controller."
  type        = map(string)
  default     = {}
  nullable    = false
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
