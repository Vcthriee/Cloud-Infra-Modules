
# ELASTICACHE SUBNET GROUP - CACHE PLACEMENT

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = {
    Name = "${var.project_name}-cache-subnet-group"
  }
}

# ELASTICACHE PARAMETER GROUP - REDIS SETTINGS

resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.project_name}-redis-params"
  family = "redis7"

  # Eviction policy when memory full
  # allkeys-lru = Least Recently Used keys evicted first
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Name = "${var.project_name}-redis-params"
  }
}

# ELASTICACHE REPLICATION GROUP - REDIS CLUSTER
# Multi-AZ with automatic failover

resource "aws_elasticache_replication_group" "main" {
  # Cluster identifier
  replication_group_id = "${var.project_name}-redis"
  
  description = "Redis cluster for session and query caching"

  # Engine configuration
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.cache_node_type  # t3.micro for dev
  num_cache_clusters   = 2  # One per AZ
  port                 = 6379
  
  parameter_group_name = aws_elasticache_parameter_group.main.name

  # High availability
  automatic_failover_enabled = true
  multi_az_enabled           = true

  # Network placement
  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.elasticache_security_group_id]

  # Encryption
  at_rest_encryption_enabled = true  # Disk encryption
  transit_encryption_enabled = true  # TLS in transit
  auth_token                 = random_password.redis_auth.result

  # Backup
  snapshot_retention_limit = 7   # Keep 7 days
  snapshot_window          = "05:00-06:00"  # 5-6 AM

  tags = {
    Name = "${var.project_name}-redis"
  }
}

# Random auth token for Redis
resource "random_password" "redis_auth" {
  length  = 32
  special = false  # Alphanumeric only for Redis
}