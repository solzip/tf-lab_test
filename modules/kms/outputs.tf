# modules/kms/outputs.tf

output "rds_key_arn" {
  description = "ARN of RDS KMS key"
  value       = aws_kms_key.rds.arn
}

output "rds_key_id" {
  description = "ID of RDS KMS key"
  value       = aws_kms_key.rds.id
}

output "s3_key_arn" {
  description = "ARN of S3 KMS key"
  value       = aws_kms_key.s3.arn
}

output "s3_key_id" {
  description = "ID of S3 KMS key"
  value       = aws_kms_key.s3.id
}

output "ebs_key_arn" {
  description = "ARN of EBS KMS key"
  value       = var.create_ebs_key ? aws_kms_key.ebs[0].arn : ""
}
