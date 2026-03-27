
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
  # Unique name
  name = "${var.project_name}-postgres-params"
  
  # PostgreSQL version family
  family = "postgres18"

  # Log slow queries (> 1 second) for optimization
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"  # milliseconds
  }

  tags = {
    Name = "${var.project_name}-postgres-params"
  }
}

# RDS PRIMARY INSTANCE - POSTGRESQL DATABASE
# Multi-AZ enabled for automatic failover

resource "aws_db_instance" "primary" {
  # Unique identifier for this database
  identifier = "${var.project_name}-postgres-primary"

  # Engine and version
  engine         = "postgres"
  engine_version = "18.2"
  
  # Instance size (t3.micro = free tier eligible)
  instance_class = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.db_allocated_storage      # Start at 20 GB
  max_allocated_storage = var.db_max_allocated_storage  # Grow to 100 GB
  storage_type          = "gp3"  # SSD, better than gp2
  storage_encrypted     = true   # Encryption at rest
  
  # Database name and credentials
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_master.result  

  # High availability - standby in different AZ
  multi_az = true

  # Network placement
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  # Backup configuration
  backup_retention_period = 35   # Keep 35 days of backups
  backup_window           = "03:00-04:00"  # 3-4 AM UTC
  maintenance_window      = "Mon:04:00-Mon:05:00"  # After backup

  # Logging
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  
  # Protection
  deletion_protection = false 
  
  # Skip final snapshot for easier destroy during development
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres-primary"
  }
}

# RDS READ REPLICA - READ SCALING
# Offload read traffic from primary

# RDS READ REPLICA - READ SCALING
# Offload read traffic from primary

resource "aws_db_instance" "replica" {
  identifier = "${var.project_name}-postgres-replica"

  # Replicate from primary instance
  replicate_source_db = aws_db_instance.primary.arn

  instance_class = var.db_instance_class
  
  storage_encrypted = true

  vpc_security_group_ids = [var.rds_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  # No backups on replica (uses primary's backups)
  backup_retention_period = 0
  
  # Single AZ is fine for replica (can recreate from primary)
  multi_az = false

  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Skip final snapshot for easier destroy during development
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres-replica"
  }

  depends_on = [aws_db_instance.primary]
}