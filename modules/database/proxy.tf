
# RDS PROXY - CONNECTION POOLING
# Reduces database connection overhead

resource "aws_db_proxy" "main" {
  # Unique name
  name = "${var.project_name}-postgres-proxy"
  
  # PostgreSQL engine
  engine_family = "POSTGRESQL"
  
  # Close idle client connections after 30 minutes
  idle_client_timeout = 1800
  
  # Require TLS encryption between client and proxy
  require_tls = true
  
  # IAM role for proxy to read Secrets Manager
  role_arn = aws_iam_role.rds_proxy.arn
  
  # Network placement
  vpc_security_group_ids = [var.rds_proxy_security_group_id]
  vpc_subnet_ids         = var.private_data_subnet_ids

  # Authentication configuration
  auth {
    auth_scheme = "SECRETS"  # Use Secrets Manager
    description = "RDS Proxy auth"
    iam_auth    = "DISABLED" # Use native PostgreSQL auth
    secret_arn  = aws_secretsmanager_secret.db_password.arn
  }

  tags = {
    Name = "${var.project_name}-postgres-proxy"
  }
}

# Target group - defines connection pooling settings
resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    # Max connections as % of database max
    max_connections_percent = 100
    
    # Idle connections to keep warm
    max_idle_connections_percent = 50
    
    # Seconds to wait for available connection
    connection_borrow_timeout = 120
  }
}

# Attach primary database to proxy
resource "aws_db_proxy_target" "main" {
  db_proxy_name = aws_db_proxy.main.name
  
  target_group_name = aws_db_proxy_default_target_group.main.name
  
  # Point to primary (failover handled automatically)
  db_instance_identifier = aws_db_instance.primary.identifier
}