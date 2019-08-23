resource "aws_elasticache_parameter_group" "redis" {
  family = "redis5.0"
  name = "dr-demo-cache"
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "dr-demo-redis"
  engine               = "redis"
  node_type            = "cache.t2.small"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  engine_version       = "5.0.4"
  port                 = 6379
  subnet_group_name = data.terraform_remote_state.basic.outputs.cache_subnet_group_id
  security_group_ids = [data.terraform_remote_state.basic.outputs.db_sg_id]
}