# environments/local/backend.tf
# Terraform State Backend 설정

terraform {
  backend "s3" {}
}
