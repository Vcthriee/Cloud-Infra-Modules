
output "alb_dns_name" {
  description = "ALB DNS name for CloudFront origin"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn" {
  description = "Target group ARN for other integrations"
  value       = aws_lb_target_group.main.arn
}

output "asg_name" {
  description = "Auto Scaling Group name for monitoring"
  value       = aws_autoscaling_group.main.name
}