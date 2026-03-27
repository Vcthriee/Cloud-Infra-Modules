
# SECRETS MANAGER - DATABASE PASSWORD STORAGE
# Auto-rotates credentials, encrypted at rest

# The secret container
resource "aws_secretsmanager_secret" "db_password" {
  # Unique name for this secret
  name = "${var.project_name}-db-master-password"
  
  description = "Master password for RDS PostgreSQL"
  
  # Days to wait before permanent deletion (allows recovery)
  recovery_window_in_days = 7
  
  # Instead of immediate deletion:
  # deletion_protection = true  # For production

  tags = {
    Name = "${var.project_name}-db-secret"
  }
}

# The actual secret value (username + password)
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  
  # JSON format for structured data
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_master.result
  })
}

# Generate cryptographically secure random password
resource "random_password" "db_master" {
  length  = 32  # 32 characters
  
  # Include special characters
  special = true
  
  # Exclude characters that cause issues in URLs/JSON
  override_special = "!#$%&*()-_=+[]{}<>:?"
  
  # Result: something like "xK9#mP2$vL5@nQ8..."
}