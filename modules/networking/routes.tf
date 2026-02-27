
# PUBLIC ROUTE TABLE - Internet-bound traffic goes to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route for all internet traffic (0.0.0.0/0 = everywhere)
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# PRIVATE APP ROUTE TABLES - Internet via NAT Gateway
# One per AZ for HA (if NAT fails, only that AZ loses outbound)
resource "aws_route_table" "private_app" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-app-rt-${var.availability_zones[count.index]}"
  }
}

# PRIVATE DATA ROUTE TABLES - No internet, local only
# Most secure - databases can't reach internet even if compromised
resource "aws_route_table" "private_data" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  # No route to 0.0.0.0/0 - completely isolated
  # Use VPC endpoints for AWS service access

  tags = {
    Name = "${var.project_name}-private-data-rt-${var.availability_zones[count.index]}"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private app subnets with their route tables
resource "aws_route_table_association" "private_app" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app[count.index].id
}

# Associate private data subnets with their route tables
resource "aws_route_table_association" "private_data" {
  count = length(var.availability_zones)
  
  subnet_id      = aws_subnet.private_data[count.index].id
  route_table_id = aws_route_table.private_data[count.index].id
}