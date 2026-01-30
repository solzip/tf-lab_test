# modules/rds/outputs.tf
# RDS 모듈 출력

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS address (hostname only)"
  value       = aws_db_instance.main.address
  sensitive   = true
}

output "rds_arn" {
  description = "RDS ARN"
  value       = aws_db_instance.main.arn
}

output "rds_resource_id" {
  description = "RDS resource ID"
  value       = aws_db_instance.main.resource_id
}
