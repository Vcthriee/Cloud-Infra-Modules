
output "alb_security_group_id" {
  description = "ALB security group for ALB creation"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "EC2 security group for ASG"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "RDS security group for database"
  value       = aws_security_group.rds.id
}

output "rds_proxy_security_group_id" {
  description = "RDS Proxy security group"
  value       = aws_security_group.rds_proxy.id
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group"
  value       = aws_security_group.elasticache.id
}