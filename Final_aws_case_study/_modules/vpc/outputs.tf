output "vpc_id" {
  value = aws_vpc.DS-VPC.id
}
output "public_subnets_id" {
  value = [for s in aws_subnet.public_subnets : s.id]  
}

output "app_subnet_id" {
  value = [for s in aws_subnet.app_subnets : s.id]  
}

output "data_subnet_id" {
  value = [for s in aws_subnet.data_subnets : s.id]
}

output "ELB_security_group" {
  value = aws_security_group.ELB_SG.id
}

output "EFS_Mount_Target_SG" {
 value = aws_security_group.EFS_Mount_Target_SG.id 
}

output "RDS_security_group" {
  value = aws_security_group.RDS_security_group.id
}   

output "Cache_security_group" {
  value = aws_security_group.Cache_security_group.id
}

output "Launch_template_security_group" {
  value = aws_security_group.Launch_template_sg.id
}