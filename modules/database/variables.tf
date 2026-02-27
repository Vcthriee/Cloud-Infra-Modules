
variable "project_name" {
  description = "Name prefix for resources"
  type        = string
}

variable "private_data_subnet_ids" {
  description = "Subnets for RDS and ElastiCache"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group for RDS"
  type        = string
}

variable "rds_proxy_security_group_id" {
  description = "Security group for RDS Proxy"
  type        = string
}

variable "elasticache_security_group_id" {
  description = "Security group for ElastiCache"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdatabase"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "cache_node_type" {
  description = "ElastiCache node size"
  type        = string
  default     = "cache.t3.micro"
}