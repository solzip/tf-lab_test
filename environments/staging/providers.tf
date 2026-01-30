# environments/local/providers.tf
# AWS Provider 설정 (LocalStack)

provider "aws" {
  region = var.aws_region

  access_key = "test"
  secret_key = "test"
  token      = "test"

  endpoints {
    s3       = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    sts      = var.localstack_endpoint
    iam      = var.localstack_endpoint
    ec2      = var.localstack_endpoint
    elb      = var.localstack_endpoint
    elbv2    = var.localstack_endpoint
    rds      = var.localstack_endpoint
  }

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  default_tags {
    tags = {
      Project = var.project_name
      Managed = "terraform"
      Env     = var.env_name
    }
  }
}
