# modules/iam/outputs.tf

output "ec2_app_role_arn" {
  description = "ARN of EC2 app role"
  value       = aws_iam_role.ec2_app.arn
}

output "ec2_app_role_name" {
  description = "Name of EC2 app role"
  value       = aws_iam_role.ec2_app.name
}

output "ec2_app_instance_profile_arn" {
  description = "ARN of EC2 app instance profile"
  value       = aws_iam_instance_profile.ec2_app.arn
}

output "ec2_app_instance_profile_name" {
  description = "Name of EC2 app instance profile"
  value       = aws_iam_instance_profile.ec2_app.name
}

output "ec2_bastion_instance_profile_name" {
  description = "Name of EC2 bastion instance profile"
  value       = var.create_bastion_role ? aws_iam_instance_profile.ec2_bastion[0].name : ""
}
