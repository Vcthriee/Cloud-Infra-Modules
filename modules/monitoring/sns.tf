
# SNS TOPIC - NOTIFICATION HUB
# Receives alarms, sends to subscribers

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name = "${var.project_name}-alerts"
  }
}

# Email subscriptions
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

# PagerDuty integration (optional)
resource "aws_sns_topic_subscription" "pagerduty" {
  count     = var.pagerduty_integration_key != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = "https://events.pagerduty.com/integration/${var.pagerduty_integration_key}/enqueue"
}