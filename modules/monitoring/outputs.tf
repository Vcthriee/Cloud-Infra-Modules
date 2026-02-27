
output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "SNS topic ARN for additional subscriptions"
  value       = aws_sns_topic.alerts.arn
}

output "log_group_name" {
  description = "Application log group name"
  value       = aws_cloudwatch_log_group.application.name
}