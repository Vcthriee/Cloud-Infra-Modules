
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

module "networking" {
  source = "../../modules/networking"

  project_name        = var.project_name
  aws_region          = var.aws_region
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_app_cidrs   = var.private_app_cidrs
  private_data_cidrs  = var.private_data_cidrs
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "database" {
  source = "../../modules/database"

  project_name                  = var.project_name
  private_data_subnet_ids       = module.networking.private_data_subnet_ids
  rds_security_group_id         = module.security.rds_security_group_id
  rds_proxy_security_group_id   = module.security.rds_proxy_security_group_id
  elasticache_security_group_id = module.security.elasticache_security_group_id
}

module "ecs" {
  source = "../../modules/ecs"

  project_name           = var.project_name
  aws_region             = var.aws_region
  environment            = "dev"
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids      = module.networking.public_subnet_ids
  private_app_subnet_ids = module.networking.private_app_subnet_ids
  alb_security_group_id  = module.security.alb_security_group_id
  ecs_security_group_id  = module.security.ecs_security_group_id

  db_proxy_endpoint = module.database.rds_proxy_endpoint
  redis_endpoint    = module.database.redis_endpoint
  db_secret_arn     = module.database.db_secret_arn
  jwt_secret_arn    = module.database.jwt_secret_arn # CHANGED: was jwt_secret

  db_name     = var.db_name
  db_username = var.db_username
  # REMOVED: db_password and jwt_secret - ECS reads from Secrets Manager instead
}