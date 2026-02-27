
resource "aws_vpc" "main" {
  # CIDR block - IP range for entire VPC (65,536 IPs)
  cidr_block = var.vpc_cidr
  
  # Enable DNS hostnames for EC2 instances (name-1a-2b-3c.region.compute.internal)
  enable_dns_hostnames = true
  
  # Enable DNS resolution within VPC
  enable_dns_support = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}