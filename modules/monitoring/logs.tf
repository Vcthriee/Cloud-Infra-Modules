
# CLOUDWATCH LOG GROUPS - CENTRALIZED LOGGING
# Aggregate logs from all services

# Application logs from EC2 instances
resource "aws_cloudwatch_log_group" "application" {
  name              = "/${var.project_name}/application"
  retention_in_days = 30  # Keep 30 days

  tags = {
    Name = "${var.project_name}-application-logs"
  }
}

# Database logs
resource "aws_cloudwatch_log_group" "database" {
  name              = "/${var.project_name}/database"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-database-logs"
  }
}

# METRIC FILTER - CREATE METRIC FROM LOGS
# Count ERROR occurrences in logs

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.project_name}-error-metric"
  pattern        = "ERROR"  # Search for ERROR in logs
  log_group_name = aws_cloudwatch_log_group.application.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = var.project_name
    value         = "1"      # Increment by 1 per match
    default_value = "0"      # 0 when no matches
    unit          = "Count"
  }
}

# Alarm on error rate
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.project_name}-error-rate-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 10

  # Math expression: errors / total requests * 100
  metric_query {
    id          = "error_rate"
    expression  = "errors / total * 100"
    label       = "Error Rate %"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "ErrorCount"
      namespace   = var.project_name
      period      = 300
      stat        = "Sum"
    }
  }

  metric_query {
    id = "total"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  alarm_description = "Warning: Error rate > 10%"
  alarm_actions     = [aws_sns_topic.alerts.arn]
}