# RDS SUBNET GROUP - DATABASE PLACEMENT
# Requires subnets in at least 2 AZs for Multi-AZ
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# RDS PARAMETER GROUP - DATABASE CONFIGURATION
# Custom settings for PostgreSQL
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-postgres-params"
  family = "postgres18"

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = {
    Name = "${var.project_name}-postgres-params"
  }
}

# RDS PRIMARY INSTANCE - POSTGRESQL DATABASE
# Multi-AZ enabled for automatic failover
resource "aws_db_instance" "primary" {
  identifier = "${var.project_name}-postgres-primary"

  engine         = "postgres"
  engine_version = "18.2"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_master.result  

  multi_az = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = 35
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  deletion_protection = false 
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres-primary"
  }
}

# NEW: Wait for primary to be fully available before creating replica
# This forces Terraform to wait 10 minutes after primary creation
# RDS needs this time to be ready for replication
resource "time_sleep" "wait_for_primary" {
  depends_on = [aws_db_instance.primary]
  create_duration = "10m"
}

# RDS READ REPLICA - READ SCALING
# Offload read traffic from primary
resource "aws_db_instance" "replica" {
  identifier = "${var.project_name}-postgres-replica"

  # Use identifier instead of ARN - forces Terraform to wait
  replicate_source_db = aws_db_instance.primary.identifier

  instance_class = var.db_instance_class
  storage_encrypted = true

  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = 0
  multi_az = false

  enabled_cloudwatch_logs_exports = ["postgresql"]
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres-replica"
  }

  # CHANGED: Now depends on time_sleep, not just primary
  # This ensures 10 minute wait before replica creation
  depends_on = [time_sleep.wait_for_primary]
}