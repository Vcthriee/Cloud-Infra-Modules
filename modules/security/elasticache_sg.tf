
# ELASTICACHE SECURITY GROUP - REDIS CACHE
# Only accepts traffic from EC2

resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-elasticache-"
  vpc_id      = var.vpc_id
  description = "Security group for ElastiCache Redis"

  # INGRESS: Redis port 6379 from EC2 only
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "Redis from EC2 only"
  }

  tags = {
    Name = "${var.project_name}-elasticache-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}