
# INTERNET GATEWAY - VPC CONNECTION TO INTERNET
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Required for NAT Gateways (they need fixed IPs)

resource "aws_eip" "nat" {
  # One EIP per AZ for high availability
  count = length(var.availability_zones)
  
  # Must be in VPC (not EC2-Classic)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }

  # Ensure IGW exists before creating EIPs
  depends_on = [aws_internet_gateway.main]
}
# Allow private instances to reach internet (updates, APIs)
# but prevent internet from reaching them

resource "aws_nat_gateway" "main" {
  count = length(var.availability_zones)
  
  # Attach EIP to NAT Gateway
  allocation_id = aws_eip.nat[count.index].id
  
  # Place in public subnet (needs public IP to talk to internet)
  subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gw-${var.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}