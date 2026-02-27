
# LAUNCH TEMPLATE - EC2 INSTANCE BLUEPRINT
# Defines how instances are configured

resource "aws_launch_template" "main" {
  name          = "${var.project_name}-launch-template"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # Security group for instances
  vpc_security_group_ids = [var.ec2_security_group_id]

  # IAM role for CloudWatch, SSM, Secrets Manager
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # Bootstrap script - runs on first boot
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_proxy_endpoint = var.db_proxy_endpoint
    redis_endpoint    = var.redis_endpoint
    environment       = var.environment
  }))

  # Instance Metadata Service v2 (more secure)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Force IMDSv2
    http_put_response_hop_limit = 1
  }

  # Detailed CloudWatch monitoring
  monitoring {
    enabled = true
  }

  # Tags applied to instances
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-instance"
    }
  }

  # Create new before destroying old (zero downtime updates)
  lifecycle {
    create_before_destroy = true
  }
}