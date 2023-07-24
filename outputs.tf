output "ready" {
  description = "Hack! Because modules with providers (cluster-apps) cannot use depends_on output value needs to be used to make sure those are provisioned in correct order."
  value = {
    tls   = "${aws_lb_listener.tls.arn}:${aws_lb_target_group.tls.id}"
    plain = "${aws_lb_listener.plain.arn}:${aws_lb_target_group.plain.id}"
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

output "sg_id" {
  description = "Security Group attached to loadbalancer"
  value       = aws_security_group.alb.id
}

output "target_group_tls_arn" {
  description = "ARN of TLS target group"
  value       = aws_lb_target_group.tls.arn
}

output "target_group_plain_arn" {
  description = "ARN of plain target group"
  value       = aws_lb_target_group.plain.arn
}
