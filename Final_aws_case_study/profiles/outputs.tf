output "current_reg" {
  value = data.aws_region.current_reg
}

output "elb_endpoint" {
  value = module.ec2-elb.url
}
