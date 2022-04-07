#Rds vars for input
variable "instance_class"{
    type = string
    default = "db.t3.small"
}

variable "db_name" {
  type = string
  default = "DS_DB"
}

variable "db_username" {
  type = string
  default = "admin"
}

variable "db_password" {
  type = string
  default = "admin123"
}

variable "db_engine_type" {
  type = string
  default = "aurora-mysql"
}

variable "db_engine_version" {
  type = string
  default = "5.7.mysql_aurora.2.07.2"
}

#Cache vars for input
variable "cache_engine" {
  type = string
  default = "memcached"
}

variable "cache_node_type" {
  type = string
  default = "cache.t3.micro"
}

variable "cache_parameter_group" {
  type = string
  default = "default.memcached1.6"
}

#Vars for VPC input
variable "cidr_block"{
	default = "10.0.0.0/16"
	description = "CIDR block of the VPC"
}

variable "subnets_cidr" {
	type = list(string)
	default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_subnets_cidr" {
	type = list(string)
	default = ["10.0.3.0/24", "10.0.4.0/24"]
}


variable "data_subnets_cidr" {
	type = list(string)
	default = ["10.0.5.0/24", "10.0.6.0/24"]
}

#ec2-elb vars for input
variable "ami_id" {
  type = string
  default = "ami-0dcc0ebde7b2e00db"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "health_check_path" {
  type = string
  default = "/wp-login.php"
}