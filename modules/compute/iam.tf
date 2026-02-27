
# IAM ROLE FOR EC2 INSTANCES
# Permissions without hardcoded credentials

# Trust policy - who can assume this role
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"  # Only EC2 service
      }
    }]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Instance profile - attaches role to EC2
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Permission policy - what EC2 can do
resource "aws_iam_role_policy" "ec2_secrets" {
  name = "${var.project_name}-ec2-secrets-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Read database password from Secrets Manager
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      },
      {
        # CloudWatch metrics and logs
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        # AWS Systems Manager (SSM) for shell access
        # Replaces SSH - more secure, fully audited
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}