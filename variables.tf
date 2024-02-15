variable "cluster_name" {
  description = "Name of the cluster will be used as suffix to all resources"
  type        = string
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