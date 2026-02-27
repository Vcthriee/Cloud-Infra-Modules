
# AUTO SCALING GROUP - MANAGES EC2 INSTANCES
# Maintains desired count, scales automatically

resource "aws_autoscaling_group" "main" {
  name = "${var.project_name}-asg"

  # Network placement - private subnets
  vpc_zone_identifier = var.private_app_subnet_ids

  # Register with ALB target group
  target_group_arns = [aws_lb_target_group.main.arn]
  
  # Use ALB health checks (not just EC2 status checks)
  health_check_type = "ELB"
  
  # Seconds to wait before health checks (allow boot)
  health_check_grace_period = 300

  # Scaling limits
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  # Use launch template
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"  # Always use latest
  }

  # Rolling instance refresh for updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50  # Keep 50% healthy
    }
    triggers = ["tag"]
  }

  # Tags propagated to instances
  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}