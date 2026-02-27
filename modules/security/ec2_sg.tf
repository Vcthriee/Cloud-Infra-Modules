
# EC2 SECURITY GROUP - APPLICATION SERVERS
# Only accepts traffic from ALB, no direct internet

resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-"
  vpc_id      = var.vpc_id
  description = "Security group for EC2 instances"

  # INGRESS: HTTP from ALB only (not from internet)
  # Uses security group reference instead of CIDR
  # If ALB IP changes, this still works
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Reference to ALB SG
    description     = "HTTP from ALB only"
  }

  # INGRESS: HTTPS from ALB only
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTPS from ALB only"
  }

  # EGRESS: All outbound (for updates, API calls)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound for updates, APIs"
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}