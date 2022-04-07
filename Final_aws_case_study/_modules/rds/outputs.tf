output "db_name" {
  value = aws_rds_cluster.RDS_cluster.database_name
}

output "db_username" {
  value = aws_rds_cluster.RDS_cluster.master_username
}

output "db_password" {
  value = aws_rds_cluster.RDS_cluster.master_password
}

output "db_endpoint" {
  value = aws_rds_cluster.RDS_cluster.endpoint
}