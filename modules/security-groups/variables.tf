# modules/security-groups/variables.tf
# Security Groups 모듈 입력 변수

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "env_name" {
  description = "Environment name (local/dev/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "admin_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to Bastion (관리자 IP만 허용)"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.admin_ssh_cidrs :
      cidr != "0.0.0.0/0"
    ])
    error_message = "보안상 0.0.0.0/0 (전체 공개)는 허용되지 않습니다. 관리자 IP를 명시적으로 지정하세요."
  }
}
