
output "vpc_id" {
  value = module.networking.vpc_id
}

output "rds_proxy_endpoint" {
  value     = module.database.rds_proxy_endpoint
  sensitive = true
}

output "redis_endpoint" {
  value     = module.database.redis_endpoint
  sensitive = true
}


