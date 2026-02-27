
# RDS PROXY SECURITY GROUP - CONNECTION POOLER
# Sits between EC2 and RDS, manages connections

resource "aws_security_group" "rds_proxy" {
  name_prefix = "${var.project_name}-rds-proxy-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS Proxy"

  # INGRESS: PostgreSQL from EC2 instances
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
    description     = "PostgreSQL from EC2 only"
  }

  # EGRESS: PostgreSQL to RDS only
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
    description     = "PostgreSQL to RDS only"
  }

  tags = {
    Name = "${var.project_name}-rds-proxy-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}