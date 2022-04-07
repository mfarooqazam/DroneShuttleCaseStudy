variable "vpc_id" {
  type = string
}
variable "Launch_template_sg" {
  type = string
}
variable "ELB_security_group" {
  type = string
}

variable "public_subnet_1_id" {
    type = string
}

variable "public_subnet_2_id" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "app_subnet_1_id" {
    type = string
}

variable "app_subnet_2_id" {
  type = string
}

#Vars for user data
variable "db_name" {
  type = string
}

variable "db_endpoint" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "aws_region" {
 type = string 
}

variable "efs_id" {
  type = string
}

variable "health_check_path" {
  type = string
}