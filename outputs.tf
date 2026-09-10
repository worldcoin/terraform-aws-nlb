output "ready" {
  description = "Hack! Because modules with providers (cluster-apps) cannot use depends_on output value needs to be used to make sure those are provisioned in correct order."
  value = {
    tls   = var.create_default_listeners && var.create_default_tls_listener ? "${aws_lb_listener.tls[0].arn}:${aws_lb_target_group.tls[0].id}" : ""
    plain = var.create_default_listeners && var.create_default_plain_listener ? "${aws_lb_listener.plain[0].arn}:${aws_lb_target_group.plain[0].id}" : ""
  }
}

output "arn" {
  description = "The ARN of the NLB."
  value       = aws_lb.nlb.arn
}

output "dns_name" {
  description = "The DNS name of the NLB."
  value       = aws_lb.nlb.dns_name
}

output "zone_id" {
  description = "The zone ID of the NLB."
  value       = aws_lb.nlb.zone_id
}

output "ssl_policy" {
  description = "SSL Policy attached to loadbalancer"
  value       = var.create_default_listeners ? aws_lb_listener.tls[0].ssl_policy : null
}

output "sg_nlb_id" {
  description = "The ID of the security group attached to NLB"
  value       = aws_security_group.nlb.id
}

output "target_group_arns" {
  description = "ARNs of target groups created from target_groups, keyed by target group name."
  value       = { for name, target_group in aws_lb_target_group.dynamic : name => target_group.arn }
}

output "listener_arns" {
  description = "ARNs of listeners created from listeners, keyed by listener name."
  value       = { for name, listener in aws_lb_listener.dynamic : name => listener.arn }
}
