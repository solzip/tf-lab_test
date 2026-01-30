# ALB Module

## 목적

Application Load Balancer 생성:
- ALB (Internet-facing)
- Target Group
- HTTP Listener

## 사용법

```hcl
module "alb" {
  source = "../../modules/alb"

  project_name      = "my-project"
  env_name          = "local"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}
```

## 입력 변수

| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_name | Project name | string | Yes |
| env_name | Environment name | string | Yes |
| vpc_id | VPC ID | string | Yes |
| public_subnet_ids | Public subnet IDs | list(string) | Yes |
| alb_sg_id | ALB SG ID | string | Yes |

## 출력

| Name | Description |
|------|-------------|
| alb_dns_name | ALB DNS name |
| alb_arn | ALB ARN |
| alb_zone_id | ALB Zone ID |
| target_group_arn | Target Group ARN |
