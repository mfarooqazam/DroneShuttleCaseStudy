terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
data "aws_caller_identity" "caller_id" {}
data "aws_region" "current_reg" {}
data "aws_availability_zones" "available-AZ" {}
module "vpc" {
    source = "../_modules/vpc"
    cidr_block = "10.0.0.0/16"
    subnets_cidr = var.subnets_cidr
    app_subnets_cidr = var.app_subnets_cidr
    data_subnets_cidr = var.data_subnets_cidr

}

module "efs" {
    source = "../_modules/efs"
    EFS_Mount_Target_SG = module.vpc.EFS_Mount_Target_SG
    app_subnet_1_id = module.vpc.app_subnet_id[0]
    app_subnet_2_id = module.vpc.app_subnet_id[1]
}   

module "rds" {
  source = "../_modules/rds"
  data_subnet_1_id = module.vpc.data_subnet_id[0]
  data_subnet_2_id = module.vpc.data_subnet_id[1]
  RDS_security_group = module.vpc.RDS_security_group
}

module "elasticache" {
  source = "../_modules/elasticache"
  app_subnet_1_id = module.vpc.app_subnet_id[0]
  app_subnet_2_id = module.vpc.app_subnet_id[1]
  Cache_security_group = module.vpc.Cache_security_group
}

module "ec2-elb" {
  source = "../_modules/ec2-elb"
  vpc_id = module.vpc.vpc_id
  ELB_security_group = module.vpc.ELB_security_group
  app_subnet_1_id = module.vpc.app_subnet_id[0]
  app_subnet_2_id = module.vpc.app_subnet_id[1]
  public_subnet_1_id = module.vpc.public_subnets_id[0]
  public_subnet_2_id = module.vpc.public_subnets_id[1]
  Launch_template_sg = module.vpc.Launch_template_security_group
  db_name = module.rds.db_name
  db_username = module.rds.db_username
  db_password = module.rds.db_password
  db_endpoint = module.rds.db_endpoint
  efs_id = module.efs.efs_id
  aws_region = data.aws_region.current_reg.name
  ami_id = var.ami_id
  instance_type = var.instance_type
  health_check_path = var.health_check_path
}