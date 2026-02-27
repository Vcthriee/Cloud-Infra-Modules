
variable "project_name" {
  description = "Name prefix for security groups"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}