# RDS PROXY SECURITY GROUP - CONNECTION POOLER
# Sits between ECS and RDS, manages connections

resource "aws_security_group" "rds_proxy" {
  name_prefix = "${var.project_name}-rds-proxy-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS Proxy"

  # INGRESS: PostgreSQL from ECS tasks
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
    description     = "PostgreSQL from ECS only"
  }

  # EGRESS: Allow all outbound (simpler, no circular dependency)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-rds-proxy-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}