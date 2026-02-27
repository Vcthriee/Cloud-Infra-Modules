
# CLOUDWATCH DASHBOARD - SINGLE PANE OF GLASS
# Visual overview of entire infrastructure health

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  # Dashboard body is JSON defining widgets
  dashboard_body = jsonencode({
    widgets = [
      # Row 1: Application Health (ALB)
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count & Latency"
          region = var.aws_region
          metrics = [
            # Request count (left Y axis)
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60 }],
            # Response time (right Y axis)
            [".", "TargetResponseTime", ".", ".", { stat = "Average", period = 60, yAxis = "right" }]
          ]
          annotations = {
            horizontal = [
              { value = var.latency_threshold, label = "Latency Threshold", color = "#ff0000" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB HTTP 5xx Errors"
          region = var.aws_region
          metrics = [
            # Target 5xx = application errors
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60, color = "#ff0000" }],
            # ELB 5xx = load balancer errors
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { stat = "Sum", period = 60 }]
          ]
        }
      },

      # Row 2: Compute (EC2)
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name, { stat = "Average", period = 60 }]
          ]
          annotations = {
            horizontal = [
              { value = 70, label = "Scale Up", color = "#ff9900" },
              { value = 30, label = "Scale Down", color = "#2ca02c" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "EC2 Memory Utilization"
          region = var.aws_region
          metrics = [
            # Custom metric from CloudWatch agent
            [var.project_name, "mem_used_percent", { stat = "Average", period = 60 }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "Auto Scaling Group Size"
          region = var.aws_region
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name, { stat = "Average", period = 60, label = "In Service" }],
            [".", "GroupPendingInstances", ".", ".", { stat = "Average", period = 60, label = "Pending" }],
            [".", "GroupTerminatingInstances", ".", ".", { stat = "Average", period = 60, label = "Terminating" }]
          ]
        }
      },

      # Row 3: Database (RDS)
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS PostgreSQL CPU & Connections"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id, { stat = "Average", period = 60 }],
            [".", "DatabaseConnections", ".", ".", { stat = "Average", period = 60, yAxis = "right" }]
          ]
          annotations = {
            horizontal = [
              { value = 80, label = "High CPU", color = "#ff0000" },
              { value = var.rds_max_connections * 0.8, label = "Conn Limit", color = "#ff0000", yAxis = "right" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS Read/Write Latency"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", var.rds_instance_id, { stat = "Average", period = 60 }],
            [".", "WriteLatency", ".", ".", { stat = "Average", period = 60 }]
          ]
        }
      },

      # Row 4: Cache (ElastiCache)
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "ElastiCache Redis CPU & Connections"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "ReplicationGroupId", var.elasticache_id, { stat = "Average", period = 60 }],
            [".", "CurrConnections", ".", ".", { stat = "Average", period = 60, yAxis = "right" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6
        properties = {
          title  = "ElastiCache Cache Hit Rate"
          region = var.aws_region
          metrics = [
            ["AWS/ElastiCache", "CacheHits", "ReplicationGroupId", var.elasticache_id, { stat = "Sum", period = 60 }],
            [".", "CacheMisses", ".", ".", { stat = "Sum", period = 60 }]
          ]
        }
      },

      # Row 5: Logs
      {
        type   = "log"
        x      = 0
        y      = 24
        width  = 24
        height = 6
        properties = {
          title   = "Application Error Logs"
          region  = var.aws_region
          query   = "SOURCE '/${var.project_name}/application' | fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20"
        }
      }
    ]
  })
}