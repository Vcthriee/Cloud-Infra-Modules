
# RDS SECURITY GROUP - POSTGRESQL DATABASE
# Only accepts traffic from RDS Proxy

resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS PostgreSQL"

  # INGRESS: PostgreSQL port 5432 from proxy only
  # No direct access from EC2 or internet
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = []
    description     = "PostgreSQL from RDS Proxy only"
  }

  # No egress rule needed - RDS is managed service
  # AWS handles outbound from database

  tags = {
    Name = "${var.project_name}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}