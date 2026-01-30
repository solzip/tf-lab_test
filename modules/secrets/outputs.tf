# modules/secrets/outputs.tf

output "secret_arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "secret_id" {
  description = "ID of the secret"
  value       = aws_secretsmanager_secret.db_password.id
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.db_password.name
}
