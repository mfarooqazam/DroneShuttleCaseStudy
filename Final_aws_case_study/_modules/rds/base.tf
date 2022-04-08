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

resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "db_subnet_group"
  subnet_ids = [var.data_subnet_1_id, var.data_subnet_2_id]
}

#Aurora DB
resource "aws_rds_cluster" "RDS_cluster" {
  cluster_identifier     = "ds-db-cluster"
  availability_zones     = data.aws_availability_zones.available-AZ.names
  engine                 = var.db_engine_type
  engine_version         = var.db_engine_version
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.id
  vpc_security_group_ids = [var.RDS_security_group]
  storage_encrypted      = true
  skip_final_snapshot = true
  tags = {
    Name = "DS_Aurora_DB"
  }
}

resource "aws_rds_cluster_instance" "RDS_DB" {
  count               = 2
  availability_zone = data.aws_availability_zones.available-AZ.names[count.index]
  identifier          = "ds-db-instance-az-${count.index+1}"
  cluster_identifier  = aws_rds_cluster.RDS_cluster.id
  instance_class      = var.instance_class
  engine              = aws_rds_cluster.RDS_cluster.engine
  engine_version      = aws_rds_cluster.RDS_cluster.engine_version
  publicly_accessible = false

}
