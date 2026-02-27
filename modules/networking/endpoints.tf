# VPC ENDPOINTS - PRIVATE AWS SERVICE ACCESS
# Allow private subnets to reach AWS services without internet
# Saves NAT Gateway costs, more secure

# S3 ENDPOINT - Gateway type (free, route table based)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  
  # Gateway endpoints modify route tables (not ENIs)
  vpc_endpoint_type = "Gateway"
  
  # Add route to all data subnet route tables
  route_table_ids = aws_route_table.private_data[*].id

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}

# SECRETS MANAGER ENDPOINT - Interface type (ENI based)
# RDS Proxy needs this to fetch database credentials
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.secretsmanager"
  
  # Interface endpoints create ENIs in your subnets (costs money)
  vpc_endpoint_type = "Interface"
  
  # Place in data subnets where RDS Proxy lives
  subnet_ids         = aws_subnet.private_data[*].id
  security_group_ids = [aws_security_group.vpc_endpoints.id]
  
  # Enable private DNS so "secretsmanager.region.amazonaws.com" 
  # resolves to endpoint IP instead of public IP
  private_dns_enabled = true

  tags = {
    Name = "${var.project_name}-secretsmanager-endpoint"
  }
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-vpce-"
  vpc_id      = aws_vpc.main.id

  # Allow HTTPS from anywhere in VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  tags = {
    Name = "${var.project_name}-vpc-endpoints-sg"
  }
}