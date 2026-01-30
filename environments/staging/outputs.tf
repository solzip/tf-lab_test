# environments/local/outputs.tf
# Local 환경 출력

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "nat_eip" {
  description = "NAT Gateway EIP"
  value       = module.vpc.nat_eip
}

# Security Groups
output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = module.security_groups.alb_sg_id
}

output "app_sg_id" {
  description = "App Security Group ID"
  value       = module.security_groups.app_sg_id
}

# ALB
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

# Compute
output "bastion_public_ip" {
  description = "Bastion Public IP"
  value       = module.compute.bastion_public_ip
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}

# RDS
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.rds_endpoint
  sensitive   = true
}
