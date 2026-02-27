
variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "rds_instance_id" {
  type = string
}

variable "elasticache_id" {
  type = string
}

variable "rds_max_connections" {
  type    = number
  default = 100
}

variable "latency_threshold" {
  type    = number
  default = 2.0
}

variable "alert_emails" {
  type    = list(string)
  default = []
}

variable "pagerduty_integration_key" {
  type      = string
  default   = ""
  sensitive = true
}