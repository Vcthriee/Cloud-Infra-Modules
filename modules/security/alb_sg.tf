
# ALB SECURITY GROUP - INTERNET-FACING LOAD BALANCER
# Controls traffic to/from Application Load Balancer

resource "aws_security_group" "alb" {
  # Name prefix allows create_before_destroy lifecycle
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = var.vpc_id
  
  description = "Security group for Application Load Balancer"

  # INGRESS: Allow HTTP from anywhere (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"           # TCP for HTTP
    cidr_blocks = ["0.0.0.0/0"]   # Any IP address
    description = "HTTP from internet"
  }

  # INGRESS: Allow HTTPS from anywhere (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # EGRESS: Allow all outbound traffic
  # ALB needs to reach EC2 instances in private subnets
  egress {
    from_port   = 0               # All ports
    to_port     = 0
    protocol    = "-1"            # All protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }

  # Create new security group before destroying old
  # Prevents downtime during updates
  lifecycle {
    create_before_destroy = true
  }
}