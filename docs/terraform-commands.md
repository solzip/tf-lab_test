# Terraform Command Guide (tf-lab)

이 문서는 **tf-lab 프로젝트에서 Terraform을 사용할 때의 표준 실행 명령어와 각 명령의 의미**를 정리한 문서이다.

---

## 실행 위치

- 모든 명령은 프로젝트 루트 디렉터리(`tf-lab/`)에서 실행한다.

---

## 환경별 설정 파일 구조

- Backend 설정 파일: `env/<env>/backend.hcl`
- 변수 값 파일: `env/<env>/terraform.tfvars`

예시 (local 환경):

- `env/local/backend.hcl`
- `env/local/terraform.tfvars`

---

## 1) 코드 포맷 정리

### terraform fmt -recursive

Terraform 코드 파일(`*.tf`, `*.tfvars`)을 Terraform 표준 스타일에 맞게 자동 정렬한다.

- 들여쓰기 및 코드 스타일 통일
- 코드 리뷰 시 diff 최소화
- 하위 디렉터리까지 모두 적용 (`env/` 포함)

```bash
terraform fmt -recursive
```

---

## 2) 구성 및 문법 검증

### terraform validate

Terraform 구성 파일이 문법적으로 올바른지 검증한다.

- HCL 문법 오류
- 정의되지 않은 변수/리소스 참조
- 타입 불일치 등 기본적인 구성 오류 확인

주의 사항:

- 실제 인프라(LocalStack/AWS)에 변경을 가하지 않는다.
- 상태(state)를 생성하거나 수정하지 않는다.

```bash
terraform validate
```

---

## 3) 초기화 및 Backend 설정 적용

### $env:AWS_ACCESS_KEY_ID="test"
### $env:AWS_SECRET_ACCESS_KEY="test"
### $env:AWS_SESSION_TOKEN="test"
### $env:AWS_DEFAULT_REGION="ap-northeast-2"
### $env:AWS_EC2_METADATA_DISABLED="true"
### terraform init -reconfigure -backend-config="env/local/backend.hcl"

Terraform 작업 디렉터리를 초기화하고 state 저장소(backend) 설정을 적용한다.

init이 수행하는 작업:

- Provider 플러그인 다운로드
- `.terraform/` 디렉터리 생성
- Backend(state 저장소) 초기화
- 모듈 다운로드(사용 시)

옵션 설명:

- `-backend-config`  
  backend.tf에 선언된 backend `"s3"`의 실제 설정값(bucket, key, endpoint, dynamodb_table 등)을 주입한다.
- `-reconfigure`  
  기존 backend 설정이 있어도 강제로 다시 구성한다.  
  환경 전환(local → dev → prod) 또는 backend 값 변경 시 권장한다.

```bash
terraform init -reconfigure -backend-config=env/local/backend.hcl
```

---

## 4) 변경 계획 확인 (Plan)

### terraform plan -var-file=env/local/terraform.tfvars

Terraform 코드, 변수 값, 현재 상태(state)를 비교하여 어떤 리소스가 생성/변경/삭제될지를 미리 계산해서 보여준다.

- 실제 리소스 변경 없음
- apply 전에 반드시 확인해야 하는 단계

```bash
terraform plan -var-file=env/local/terraform.tfvars
```

---

## 권장 실행 순서 (local 환경)

```bash
terraform fmt -recursive
terraform validate
terraform init -reconfigure -backend-config=env/local/backend.hcl
terraform plan -var-file=env/local/terraform.tfvars
```

---

## 5) 인프라 적용 (Apply)

### terraform apply -var-file=env/local/terraform.tfvars

plan 결과를 기준으로 실제 인프라를 생성/수정한다.

```bash
terraform apply -var-file=env/local/terraform.tfvars
```

---

## 6) 인프라 삭제 (Destroy)

### terraform destroy -var-file=env/local/terraform.tfvars

Terraform이 관리 중인 모든 리소스를 삭제한다.

주의:
- 운영 환경에서는 매우 신중하게 사용해야 한다.

```bash
terraform destroy -var-file=env/local/terraform.tfvars
```

---

## 7) Plan 결과 고정 후 Apply (권장)

실수 방지를 위해 plan 결과를 파일로 고정한 후 apply한다.

```bash
terraform plan -var-file=env/local/terraform.tfvars -out=tfplan
terraform apply tfplan
```

이 방식은 plan에서 확인한 변경 사항 그대로 apply를 수행한다.

---

## 요약

- `fmt`: 코드 스타일 정리
- `validate`: 문법/구성 오류 검증
- `init`: provider 및 backend 초기화
- `plan`: 변경 사항 사전 확인
- `apply`: 실제 인프라 반영
- `destroy`: 리소스 전체 제거

Terraform 작업 시 항상 아래 순서를 유지하는 것을 권장한다.

```bash
terraform fmt -recursive
terraform validate
terraform init -reconfigure -backend-config=env/local/backend.hcl
terraform plan -var-file=env/local/terraform.tfvars
terraform apply -var-file=env/local/terraform.tfvars
```