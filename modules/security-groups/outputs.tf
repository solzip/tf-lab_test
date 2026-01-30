# modules/security-groups/outputs.tf
# Security Groups 모듈 출력

output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "bastion_sg_id" {
  description = "Bastion Security Group ID"
  value       = aws_security_group.bastion.id
}

output "app_sg_id" {
  description = "Application Security Group ID"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Database Security Group ID"
  value       = aws_security_group.db.id
}
