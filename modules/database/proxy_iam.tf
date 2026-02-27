
# IAM ROLE FOR RDS PROXY
# Allows proxy to read database credentials

# Trust policy - who can assume this role
resource "aws_iam_role" "rds_proxy" {
  name = "${var.project_name}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"  # Only RDS service
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-rds-proxy-role"
  }
}

# Permission policy - what role can do
resource "aws_iam_role_policy" "rds_proxy_secrets" {
  name = "${var.project_name}-rds-proxy-secrets-policy"
  role = aws_iam_role.rds_proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"  # Read password
      ]
      # Only this specific secret
      Resource = aws_secretsmanager_secret.db_password.arn
    }]
  })
}