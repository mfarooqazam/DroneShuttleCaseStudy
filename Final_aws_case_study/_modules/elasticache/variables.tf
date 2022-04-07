variable "app_subnet_1_id" {
  type = string
}
variable "app_subnet_2_id" {
  type = string
}

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

variable "Cache_security_group" {
  type = string
}

variable "AZs" {
  type = list(string)
  default = ["a","b"]
}
