
# Output values - passed to other modules

output "vpc_id" {
  description = "VPC ID for security groups and other resources"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs for EC2"
  value       = aws_subnet.private_app[*].id
}

output "private_data_subnet_ids" {
  description = "List of private data subnet IDs for RDS and ElastiCache"
  value       = aws_subnet.private_data[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs for route table configuration"
  value       = aws_nat_gateway.main[*].id
}