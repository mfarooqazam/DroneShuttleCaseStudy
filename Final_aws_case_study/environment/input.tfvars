#Vpc module
#Rds vars for input
instance_class      = "db.t3.small"
db_name             = "DS_DB"
db_username         = "admin"
db_password         = "admin123"
db_engine_type      = "aurora-mysql"
db_engine_version   = "5.7.mysql_aurora.2.07.2"

#Cache vars for input
cache_engine         = "memcached"
cache_node_type      = "cache.t3.micro"
cache_parameter_group="default.memcached1.6"

#Vars for VPC input
cidr_block           = "10.0.0.0/16"
subnets_cidr         = ["10.0.1.0/24", "10.0.2.0/24"]
app_subnets_cidr     = ["10.0.3.0/24", "10.0.4.0/24"]
data_subnets_cidr    = ["10.0.5.0/24", "10.0.6.0/24"]

#ec2-elb vars for input
ami_id               = "ami-0dcc0ebde7b2e00db"
instance_type        = "t2.micro"
health_check_path    = "/wp-login.php"
