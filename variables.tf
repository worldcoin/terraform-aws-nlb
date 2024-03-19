variable "cluster_name" {
  description = "Name of the cluster will be used as suffix to all resources"
  type        = string
}

variable "name" {
  description = "Name of the NLB, overrides default naming"
  type        = string
  default     = ""
}

variable "application" {
  description = "(namespace/app) - Name of application which will be connected to this NLB"
  type        = string
}

variable "acm_arn" {
  description = "ARN for ACM certificate used for TLS"
  type        = string
}

variable "acm_extra_arns" {
  description = "ARNs of ACM certificates used for TLS, attached as additional certificates to the main NLB"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID where the NLB will be deployed"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnets to use"
  type        = list(string)
}

variable "name_suffix" {
  description = "Part of the name used to differentiate NLBs for multiple traefik instances"
  type        = string
  default     = ""
}

variable "internal" {
  description = "Set NLB to be internal (available only within VPC)"
  type        = bool
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
}

variable "health_check_port" {
  description = "Port used for health check for listener"
  type        = number
  default     = -1
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
}
