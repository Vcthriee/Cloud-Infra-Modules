# Cloud-Infra-Modules

> Production-grade, reusable AWS infrastructure modules built with Terraform. Designed to be consumed by any project that needs a secure, scalable cloud foundation without building it from scratch.

---

## What Is This?

This repository is a library of reusable Terraform modules that provision a complete, production-ready AWS infrastructure stack. Instead of writing infrastructure code for every new project, you point your project at these modules and get a fully configured, secure environment in minutes.

**In plain English:** Think of this as a blueprint. Any application that needs to run on AWS can use these modules to get a VPC, database, caching layer, and container platform — all pre-configured with security best practices — without having to figure any of it out themselves.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC                               │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐                       │
│  │ Public Subnet│    │ Public Subnet│  ← Internet Gateway   │
│  │ af-south-1a  │    │ af-south-1b  │  ← ALB                │
│  └──────┬───────┘    └──────┬───────┘                       │
│         │ NAT GW            │ NAT GW                        │
│  ┌──────▼───────┐    ┌──────▼───────┐                       │
│  │ Private App  │    │ Private App  │  ← ECS Fargate Tasks  │
│  │ af-south-1a  │    │ af-south-1b  │                       │
│  └──────┬───────┘    └──────┬───────┘                       │
│         │                   │                               │
│  ┌──────▼───────┐    ┌──────▼───────┐                       │
│  │ Private Data │    │ Private Data │  ← RDS + ElastiCache  │
│  │ af-south-1a  │    │ af-south-1b  │                       │
│  └──────────────┘    └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

**Traffic flow:** Internet → ALB → ECS Tasks → RDS Proxy → RDS PostgreSQL

---

## Modules

### `modules/networking`
Provisions the entire network layer.

| Resource | Details |
|---|---|
| VPC | Configurable CIDR, DNS enabled |
| Public Subnets | 2x across availability zones, internet-facing |
| Private App Subnets | 2x across AZs, ECS workloads |
| Private Data Subnets | 2x across AZs, databases only |
| Internet Gateway | Public internet access |
| NAT Gateways | 2x (one per AZ) for private subnet outbound |
| Elastic IPs | Attached to NAT Gateways |
| Route Tables | Public, private-app, private-data |
| VPC Endpoints | S3 (Gateway), Secrets Manager (Interface) |

### `modules/security`
Provisions all security groups with least-privilege rules.

| Security Group | Allows |
|---|---|
| ALB | Port 80/443 from internet |
| ECS | Port 80 from ALB only |
| RDS Proxy | Port 5432 from ECS only |
| RDS | Port 5432 from RDS Proxy only |
| ElastiCache | Port 6379 from ECS only |
| VPC Endpoints | Port 443 from within VPC only |

### `modules/database`
Provisions the full data layer.

| Resource | Details |
|---|---|
| RDS PostgreSQL Primary | Multi-AZ, gp3 storage, encrypted, 35-day backups |
| RDS PostgreSQL Replica | Read replica for query offloading |
| RDS Parameter Group | Custom PostgreSQL config (slow query logging) |
| RDS Subnet Group | Multi-AZ placement |
| RDS Proxy | Connection pooling, TLS required, Secrets Manager auth |
| ElastiCache Redis | Redis 7, auth token, encrypted in transit |
| ElastiCache Parameter Group | allkeys-lru eviction policy |
| Secrets Manager | Auto-generated passwords stored securely |
| IAM Role | RDS Proxy access to Secrets Manager |

### `modules/ecs`
Provisions the container platform.

| Resource | Details |
|---|---|
| ECS Cluster | Fargate, Container Insights enabled |
| ECR Repository | Image scanning on push, 30-image lifecycle policy |
| Application Load Balancer | Public-facing, HTTP listener |
| Target Group | IP-based, `/health` health check |
| CloudWatch Log Group | 7-day retention |
| IAM Execution Role | AmazonECSTaskExecutionRolePolicy |
| IAM Task Role | Secrets Manager access for app containers |

---

## Remote State

Terraform state is stored remotely and locked to prevent concurrent operations.

| Component | Resource |
|---|---|
| State Storage | S3 bucket with versioning and encryption |
| State Locking | DynamoDB table |
| Region | af-south-1 (Cape Town) |

---

## CI/CD Pipeline

Two GitHub Actions workflows manage the full infrastructure lifecycle.

### Deploy (`terraform-deploy.yml`)
Triggers on push to `main` or `dev`.

| Branch | What Happens |
|---|---|
| `dev` | Init → Format Check → Validate → Plan (no apply) |
| `main` | Init → Format Check → Validate → Plan → **Apply** |

### Destroy (`terraform-destroy.yml`)
Manual trigger only. Requires typing `DESTROY` to confirm. Prevents accidental deletion.

### Authentication
Uses **GitHub Actions OIDC** — no static AWS credentials stored anywhere. GitHub assumes an IAM role directly via a trust policy.

---

## How to Consume These Modules

Create a new Terraform project and reference the modules directly from GitHub:

```hcl
# main.tf

module "networking" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/networking"

  project_name        = "my-app"
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["af-south-1a", "af-south-1b"]
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_cidrs   = ["10.0.3.0/24", "10.0.4.0/24"]
  private_data_cidrs  = ["10.0.5.0/24", "10.0.6.0/24"]
}

module "security" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/security"

  project_name = "my-app"
  vpc_id       = module.networking.vpc_id
}

module "database" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/database"

  project_name                  = "my-app"
  private_data_subnet_ids       = module.networking.private_data_subnet_ids
  rds_security_group_id         = module.security.rds_security_group_id
  rds_proxy_security_group_id   = module.security.rds_proxy_security_group_id
  elasticache_security_group_id = module.security.elasticache_security_group_id
}

module "ecs" {
  source = "github.com/Vcthriee/Cloud-Infra-Modules//modules/ecs"

  project_name            = "my-app"
  vpc_id                  = module.networking.vpc_id
  public_subnet_ids       = module.networking.public_subnet_ids
  private_app_subnet_ids  = module.networking.private_app_subnet_ids
  alb_security_group_id   = module.security.alb_security_group_id
  ecs_security_group_id   = module.security.ecs_security_group_id
}
```

---

## Prerequisites

- Terraform `>= 1.6.0`
- AWS CLI configured with appropriate permissions
- S3 bucket and DynamoDB table for remote state (create once per AWS account)
- GitHub Actions OIDC role (for CI/CD)

---

## Module Inputs

### `networking`

| Variable | Type | Description |
|---|---|---|
| `project_name` | string | Prefix for all resource names |
| `vpc_cidr` | string | CIDR block for the VPC |
| `availability_zones` | list(string) | List of AZs to deploy across |
| `public_subnet_cidrs` | list(string) | CIDR blocks for public subnets |
| `private_app_cidrs` | list(string) | CIDR blocks for private app subnets |
| `private_data_cidrs` | list(string) | CIDR blocks for private data subnets |

### `database`

| Variable | Type | Default | Description |
|---|---|---|---|
| `project_name` | string | — | Prefix for all resource names |
| `private_data_subnet_ids` | list(string) | — | Subnet IDs for database placement |
| `rds_security_group_id` | string | — | Security group for RDS |
| `rds_proxy_security_group_id` | string | — | Security group for RDS Proxy |
| `elasticache_security_group_id` | string | — | Security group for ElastiCache |
| `db_instance_class` | string | `db.t3.micro` | RDS instance size |
| `db_allocated_storage` | number | `20` | Initial storage in GB |
| `db_max_allocated_storage` | number | `100` | Max storage for autoscaling |
| `db_name` | string | `appdatabase` | Database name |
| `db_username` | string | `dbadmin` | Master username |
| `cache_node_type` | string | `cache.t3.micro` | ElastiCache node size |

---

## Module Outputs

| Output | Description |
|---|---|
| `vpc_id` | VPC ID for use in other modules |
| `public_subnet_ids` | Public subnet IDs |
| `private_app_subnet_ids` | Private app subnet IDs |
| `private_data_subnet_ids` | Private data subnet IDs |
| `rds_proxy_endpoint` | RDS Proxy connection endpoint (sensitive) |
| `redis_endpoint` | ElastiCache Redis endpoint (sensitive) |

---

## Security Highlights

- All databases in private subnets — no public access
- RDS only reachable through RDS Proxy — no direct connections
- All passwords auto-generated by Terraform and stored in AWS Secrets Manager
- Storage encrypted at rest on all RDS and ElastiCache resources
- TLS required on RDS Proxy connections
- VPC Endpoints for S3 and Secrets Manager — traffic never leaves AWS network
- Security groups follow least-privilege — each layer only accepts traffic from the layer above it
- GitHub Actions uses OIDC — zero static credentials anywhere in the pipeline

---

## Author

**Victory Arikpo** — Cloud Infrastructure / DevOps Engineer  
GitHub: [github.com/Vcthriee](https://github.com/Vcthriee)