
# PUBLIC SUBNETS - Resources with public IPs
# Used for: ALB, NAT Gateways
resource "aws_subnet" "public" {
  # Create one subnet per AZ (count = length of AZs list)
  count = length(var.availability_zones)
  
  # Link to our VPC
  vpc_id = aws_vpc.main.id
  
  # CIDR block - slice of VPC range
  # count.index = 0 for first AZ, 1 for second, etc.
  cidr_block = var.public_subnet_cidrs[count.index]
  
  # Which AZ this subnet lives in
  availability_zone = var.availability_zones[count.index]
  
  # Auto-assign public IPs to instances launched here
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${var.availability_zones[count.index]}"
    Type = "Public"
    # Tags for Kubernetes or other tools to discover subnets
    "kubernetes.io/role/elb" = "1"
  }
}

# PRIVATE APP SUBNETS - Application servers
# Used for: EC2 instances, no direct internet access
resource "aws_subnet" "private_app" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  # No public IPs - instances use NAT Gateway for outbound
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-app-${var.availability_zones[count.index]}"
    Type = "Private-App"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# PRIVATE DATA SUBNETS - Databases and cache
# Used for: RDS, ElastiCache, most isolated
resource "aws_subnet" "private_data" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_data_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-data-${var.availability_zones[count.index]}"
    Type = "Private-Data"
  }
}