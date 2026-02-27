
# CRITICAL ALARMS - IMMEDIATE RESPONSE NEEDED
# Page on-call engineer immediately

# ALB 5xx errors - application is broken
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2      # 2 consecutive periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60     # 1 minute periods
  statistic           = "Sum"
  threshold           = 10     # More than 10 errors
  alarm_description   = "Critical: ALB 5xx errors > 10 in 2 minutes"
  
  # Actions on alarm state
  alarm_actions = [aws_sns_topic.alerts.arn]  # Notify when alarm triggers
  ok_actions    = [aws_sns_topic.alerts.arn]  # Notify when resolved

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Severity = "critical"
  }
}

# RDS CPU - database overloaded
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3      # 3 periods = 15 minutes
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300    # 5 minute periods
  statistic           = "Average"
  threshold           = 85     # 85% CPU
  alarm_description   = "Critical: RDS CPU > 85% for 15 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Severity = "critical"
  }
}

# WARNING ALARMS - REVIEW SOON
# Not immediate emergency, but investigate

# RDS connections - approaching limit
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-rds-connections-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_max_connections * 0.8  # 80% of max
  alarm_description   = "Warning: RDS connections > 80% of max"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Severity = "warning"
  }
}

# ALB latency - slow application
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.project_name}-alb-latency-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p99"  # 99th percentile (worst 1%)
  threshold           = var.latency_threshold
  alarm_description   = "Warning: ALB p99 latency > ${var.latency_threshold}s"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Severity = "warning"
  }
}

# ASG high CPU - consider scaling
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "${var.project_name}-asg-cpu-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Warning: ASG CPU > 70%, consider scaling"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  tags = {
    Severity = "warning"
  }
}

# ElastiCache evictions - cache too small
resource "aws_cloudwatch_metric_alarm" "elasticache_evictions" {
  alarm_name          = "${var.project_name}-elasticache-evictions-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Warning: Redis evictions > 100, cache may be undersized"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ReplicationGroupId = var.elasticache_id
  }

  tags = {
    Severity = "warning"
  }
}