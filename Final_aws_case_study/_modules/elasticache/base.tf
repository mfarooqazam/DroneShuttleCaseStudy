terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
data "aws_region" "current_reg" {}
data "aws_availability_zones" "available-AZ" {}

resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name = "elasticache-subnet-group"
  subnet_ids = [var.app_subnet_1_id,var.app_subnet_2_id]
}

#Memcached ElasticCache
resource "aws_elasticache_cluster" "DS_Cache" {
  cluster_id                   = "ds-elasticache"
  preferred_availability_zones = [data.aws_availability_zones.available-AZ.names[0], data.aws_availability_zones.available-AZ.names[1]]
  engine                       = var.cache_engine
  node_type                    = var.cache_node_type
  num_cache_nodes              = 2
  parameter_group_name         = var.cache_parameter_group
  port                         = 11211
  az_mode                      = "cross-az"
  security_group_ids           = [var.Cache_security_group]
  subnet_group_name            = aws_elasticache_subnet_group.cache_subnet_group.id
  tags = {
    Name = "DS_Cache"
  }
}
