# RDS Module

## 목적

RDS MySQL 데이터베이스 생성:
- DB Subnet Group
- DB Parameter Group (UTF-8)
- RDS Instance

## 사용법

```hcl
module "rds" {
  source = "../../modules/rds"

  project_name              = "my-project"
  env_name                  = "local"
  private_db_subnet_ids     = module.vpc.private_db_subnet_ids
  db_sg_id                  = module.security_groups.db_sg_id
  db_engine                 = "mysql"
  db_engine_version         = "8.0.35"
  db_parameter_group_family = "mysql8.0"
  db_instance_class         = "db.t3.micro"
  db_name                   = "mydb"
  db_username               = "admin"
  db_password               = var.db_password
  db_multi_az               = false
}
```

## 입력 변수

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | - | Yes |
| env_name | Environment name | string | - | Yes |
| private_db_subnet_ids | Private DB subnet IDs | list(string) | - | Yes |
| db_sg_id | DB SG ID | string | - | Yes |
| db_engine | DB engine | string | mysql | No |
| db_engine_version | DB version | string | 8.0.35 | No |
| db_parameter_group_family | Parameter group family | string | mysql8.0 | No |
| db_instance_class | Instance class | string | db.t3.micro | No |
| db_name | Database name | string | - | Yes |
| db_username | Username | string | - | Yes |
| db_password | Password (sensitive) | string | - | Yes |
| db_multi_az | Enable Multi-AZ | bool | false | No |

## 출력

| Name | Description |
|------|-------------|
| rds_endpoint | RDS endpoint (sensitive) |
| rds_address | RDS address (sensitive) |
| rds_arn | RDS ARN |
| rds_resource_id | RDS resource ID |
