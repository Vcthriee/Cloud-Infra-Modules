
variable "project_name" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "route53_zone_id" {
  type = string
}

variable "origin_verify_header" {
  type      = string
  sensitive = true
}

variable "alb_dns_name" {
  type = string
}