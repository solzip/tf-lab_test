# modules/iam/variables.tf

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs to grant access"
  type        = list(string)
  default     = ["*"]
}

variable "enable_s3_access" {
  description = "Enable S3 read access"
  type        = bool
  default     = true
}

variable "enable_session_manager" {
  description = "Enable AWS Systems Manager Session Manager"
  type        = bool
  default     = false
}

variable "create_bastion_role" {
  description = "Create IAM role for Bastion host"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
