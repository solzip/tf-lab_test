# modules/secrets/variables.tf

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "db_master_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "db_master_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_endpoint" {
  description = "RDS endpoint"
  type        = string
  default     = ""
}

variable "enable_rotation" {
  description = "Enable automatic password rotation"
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "Lambda ARN for password rotation"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
