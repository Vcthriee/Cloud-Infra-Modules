
variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "ecs_security_group_id" {
  type = string
}

variable "db_proxy_endpoint" {
  type = string
}

variable "redis_endpoint" {
  type = string
}

# ARN of the database secret in Secrets Manager
# ECS reads the actual password from here at runtime
variable "db_secret_arn" {
  type = string
}

# ARN of the JWT secret in Secrets Manager
# ECS reads the actual JWT secret from here at runtime
variable "jwt_secret_arn" {
  type = string
}

variable "ecs_cpu" {
  type    = string
  default = "256"
}

variable "ecs_memory" {
  type    = string
  default = "1024"
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}

variable "ecs_min_count" {
  type    = number
  default = 1
}

variable "ecs_max_count" {
  type    = number
  default = 10
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}