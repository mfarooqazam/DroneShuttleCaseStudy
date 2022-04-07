variable "data_subnet_1_id" {
  type = string
}
variable "data_subnet_2_id" {
  type = string
}

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
variable "RDS_security_group" {
  type = string
}



