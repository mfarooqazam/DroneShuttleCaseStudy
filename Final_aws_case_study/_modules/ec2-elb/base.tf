terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
data "aws_availability_zones" "available-AZ" {}

#Application load balancer
resource "aws_lb" "DS-ALB" {
  name = "DS-app-LoadBalancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [var.ELB_security_group]
  subnets = [var.public_subnet_1_id,var.public_subnet_2_id]
  idle_timeout = "70"

  tags = {
    Name = "DS ALB"
  }
}

#Target group
resource "aws_lb_target_group" "ds_target_group" {
  name = "ds-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 10
    timeout             = 50
    interval            = 60
    path                = var.health_check_path
  }
}

#Listener
resource "aws_lb_listener" "Listener" {
  load_balancer_arn = aws_lb.DS-ALB.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ds_target_group.arn
  }
  depends_on = [aws_lb_target_group.ds_target_group,aws_lb.DS-ALB]
}
#Userdata Bash Script variables
data "template_file" "user-data" {
  template = file("${path.module}/user-data.sh")
  depends_on = [var.db_name,var.db_username,var.db_endpoint,var.db_password,var.efs_id,var.aws_region]
  vars = {
        DB_NAME                    = var.db_name
        DB_HOSTNAME                = var.db_endpoint
        DB_USERNAME                = var.db_username
        DB_PASSWORD                = var.db_password
        WP_ADMIN                   = "WPADMIN"
        WP_PASSWORD                = "WPADMIN123"
        WP_EMAIL                   = "xyz@xyz.com"
        LB_HOSTNAME                = aws_lb.DS-ALB.dns_name
        EFSMOUNTID                 = var.efs_id
        AWSREGION                  = var.aws_region
  }
}

#Launch template
resource "aws_launch_template" "DS_LT" {
  name_prefix = "DS-LT"
  description = "Launch template with dynamically insterted user data"
  image_id = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [var.Launch_template_sg]
  monitoring {
      enabled = true
  }
  private_dns_name_options {
      hostname_type = "ip-name"
  }
  ebs_optimized = false
  user_data = base64encode(data.template_file.user-data.rendered)
  
  tags = {
      Name = "DS-LaunchTemplate"
  }
}


#Autoscaling group
resource "aws_autoscaling_group" "DS_ASG" {
  vpc_zone_identifier = [var.app_subnet_1_id,var.app_subnet_2_id]
  target_group_arns = [aws_lb_target_group.ds_target_group.arn]
  
  desired_capacity = 1
  max_size = 4
  min_size = 1
  health_check_type = "ELB"
  launch_template {
    id = aws_launch_template.DS_LT.id
    version = "$Latest"
  }
}
