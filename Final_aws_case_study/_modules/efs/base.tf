terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

#create a EFS File system
resource "aws_efs_file_system" "DS-EFS" {
  creation_token = "DS-EFS"
  encrypted      = true
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    Name = "Shared EFS"
  }
}

#Efs mount target to subnet in first AZ
resource "aws_efs_mount_target" "EFS_mount_target_1" {
  file_system_id  = aws_efs_file_system.DS-EFS.id
  subnet_id       = var.app_subnet_1_id
  security_groups = [var.EFS_Mount_Target_SG]
}

#Efs mount target to other subnet
resource "aws_efs_mount_target" "EFS_mount_target_2" {
  file_system_id  = aws_efs_file_system.DS-EFS.id
  subnet_id       = var.app_subnet_2_id
  security_groups = [var.EFS_Mount_Target_SG]
}