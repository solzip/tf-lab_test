# Compute Module

## 목적

EC2 컴퓨팅 리소스 생성:
- Launch Template
- Auto Scaling Group
- Auto Scaling Policy (CPU 기반)
- Bastion Host

## 사용법

```hcl
module "compute" {
  source = "../../modules/compute"

  project_name       = "my-project"
  env_name           = "local"
  ami_id             = "ami-12345678"
  instance_type      = "t3.micro"
  private_subnet_ids = module.vpc.private_app_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  app_sg_id          = module.security_groups.app_sg_id
  bastion_sg_id      = module.security_groups.bastion_sg_id
  target_group_arn   = module.alb.target_group_arn
  user_data          = file("user-data.sh")
}
```

## 입력 변수

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | - | Yes |
| env_name | Environment name | string | - | Yes |
| ami_id | AMI ID | string | - | Yes |
| instance_type | Instance type | string | t3.micro | No |
| private_subnet_ids | Private subnet IDs | list(string) | - | Yes |
| public_subnet_ids | Public subnet IDs | list(string) | - | Yes |
| app_sg_id | App SG ID | string | - | Yes |
| bastion_sg_id | Bastion SG ID | string | - | Yes |
| target_group_arn | Target Group ARN | string | - | Yes |
| asg_min_size | ASG min size | number | 2 | No |
| asg_max_size | ASG max size | number | 4 | No |
| asg_desired_capacity | ASG desired | number | 2 | No |
| user_data | User data script | string | "" | No |

## 출력

| Name | Description |
|------|-------------|
| asg_name | Auto Scaling Group name |
| asg_arn | Auto Scaling Group ARN |
| bastion_instance_id | Bastion Instance ID |
| bastion_public_ip | Bastion Public IP |
