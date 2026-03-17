
output "alb_security_group_id" {
  description = "ALB security group for ALB creation"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS security group for ECS tasks"
  value       = aws_security_group.ecs.id
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
