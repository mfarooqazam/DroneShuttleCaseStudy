terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
data "aws_availability_zones" "available-AZ" {}
data "aws_region" "current_reg" {}

#VPC
resource "aws_vpc" "DS-VPC" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "Name" = "Final-DS-VPC"
  }
}

#Public Subnets
resource "aws_subnet" "public_subnets" {
  count      = length(var.subnets_cidr)
  vpc_id     = aws_vpc.DS-VPC.id  
  cidr_block = element(var.subnets_cidr,count.index)
  availability_zone = data.aws_availability_zones.available-AZ.names[count.index]

  tags = {
    Name = "PublicSubnet-${count.index+1}"
  }
}

# Private Subnet - App Layer
resource "aws_subnet" "app_subnets" {
  count      = length(var.app_subnets_cidr)
  vpc_id     = aws_vpc.DS-VPC.id
  cidr_block = element(var.app_subnets_cidr,count.index)
  availability_zone = data.aws_availability_zones.available-AZ.names[count.index]

  tags = {
    Name = "AppSubnet-${count.index+1}"
  }
}

# Private Subnet - Data Layer
resource "aws_subnet" "data_subnets" {
  count      = length(var.data_subnets_cidr)
  vpc_id     = aws_vpc.DS-VPC.id
  cidr_block = element(var.data_subnets_cidr,count.index)
  availability_zone = data.aws_availability_zones.available-AZ.names[count.index]

  tags = {
    Name = "DataSubnet-${count.index+1}"
  }
}

#IGW
resource "aws_internet_gateway" "IGW-DS" {
  vpc_id = aws_vpc.DS-VPC.id
  tags = {
    "Name" = "IGW-DS"
  }
}

# Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.DS-VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW-DS.id 
    }

  tags = {
    Name = "publicRouteTable"
  }
}
resource "aws_route_table_association" "public" {
  count          = length(var.subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnets.*.id,count.index)
  route_table_id = aws_route_table.public_rt.id
}


# Elastic-IP (eip) for NAT-1 and NAT-2
resource "aws_eip" "eip" {
  count      = 2
  vpc        = true
  depends_on = [aws_internet_gateway.IGW-DS]

}

# private NAT 1 & NAT 2
resource "aws_nat_gateway" "nat" {
  count         = length(var.subnets_cidr)
  allocation_id = element(aws_eip.eip.*.id,count.index)
  subnet_id     = element(aws_subnet.public_subnets.*.id,count.index)

  tags = {
    Name  = "NatPrivate-${count.index+1}"
  }
}

#Creating Route table for private subnet
resource "aws_route_table" "private_rt" {
  count =  2
  vpc_id = aws_vpc.DS-VPC.id
  tags = {
    Name = "privateRouteTable-${count.index+1}"
    }
}

#Creating Routing to NAT gateway
resource "aws_route" "private_nat_gateway" {
  count                  =  2
  route_table_id         = element(aws_route_table.private_rt.*.id,count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat.*.id,count.index)
}

#Route table associations for nat 1
resource "aws_route_table_association" "app-1" {
  subnet_id      =  aws_subnet.app_subnets[0].id  
  route_table_id =  aws_route_table.private_rt[0].id
}

resource "aws_route_table_association" "data-1" {
  subnet_id      =  aws_subnet.data_subnets[0].id 
  route_table_id =  aws_route_table.private_rt[0].id
}

#Route table associations for nat 2
resource "aws_route_table_association" "app-2" {
  subnet_id      =  aws_subnet.app_subnets[1].id  
  route_table_id =  aws_route_table.private_rt[1].id
}

resource "aws_route_table_association" "data-2" {
  subnet_id      =  aws_subnet.data_subnets[1].id 
  route_table_id =  aws_route_table.private_rt[1].id
}

# Security Group for Elastic load balancer
resource "aws_security_group" "ELB_SG" {
  name        = "ELB_security_group"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.DS-VPC.id

  ingress {
    description      = "HTTP to App Instance"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ELB security group"
  }
}

#Security group for EFS
resource "aws_security_group" "EFS_Mount_Target_SG" {
  name        = "EFS mount target SG"
  description = "Allows traffic between EFS and EC2s"
  vpc_id      = aws_vpc.DS-VPC.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ELB_SG.id]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
 }

 tags = {
   Name = "EFS mount targets SG"
 }
}

#Security group for rds
resource "aws_security_group" "RDS_security_group" {
  name        = "RDS Security Group"
  description = "Traffic to rds"
  vpc_id      = aws_vpc.DS-VPC.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
   Name = "RDS_Security_Group"
  }
}

#Security group for elasticache
resource "aws_security_group" "Cache_security_group" {
  name        = "ElastiCache_Security_Group"
  description = "Allows traffic to cache"
  vpc_id      = aws_vpc.DS-VPC.id

  ingress {
    from_port   = 11211
    to_port     = 11211
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Cache security group"
  }
}

#Security group for launch template
resource "aws_security_group" "Launch_template_sg" {
  name        = "Launch_template_sg"
  description = "Security Group allowing HTTP traffic from AppInstanceSecurityGroup"
  vpc_id      = aws_vpc.DS-VPC.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.ELB_SG.id}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Launch template sg"
  }
}
