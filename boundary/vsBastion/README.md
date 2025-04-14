# Boundary SSH Terraform Code

## HCP Boundary, Worker Setting
📌 개요

이 디렉토리는 HashiCorp Cloud Platform(HCP)에서 제공하는 Boundary와 Worker를 자동으로 구성하기 위한 Terraform 코드들을 포함합니다.

🛠 주요 기능
	•	HCP Boundary 클러스터 정보 불러오기
	•	Boundary Worker EC2 인스턴스 자동 생성 및 구성
	•	Worker 초기화 및 Registration Token 자동 발급 및 등록

- 변수 예시
```bash
vpc_id                = "vpc-xxxxxxx"
pub_subnet_id         = "subnet-xxxxxxx"
key_name              = "my-keypair"
private_key_path      = "~/.ssh/my-key.pem"
hcp_boundary_cluster_id = "hcp-cluster-id"
boundary_addr         = "https://boundary-cluster.boundary.hashicorp.cloud"
boundary_admin_id     = "admin"
boundary_admin_password = "your-password"
```
---

## Boundary Target Host Setting

📌 개요

이 디렉토리는 EC2 인스턴스를 Boundary Target으로 등록하고, SSH 세션을 위한 Credential Store, Host Catalog 및 Target 리소스를 구성합니다.

🛠 주요 기능
	•	Static Host Catalog 생성
	•	EC2 인스턴스를 Boundary Host로 등록
	•	Host Set, Target 리소스 구성
	•	SSH Key 기반 Credential Store 구성

- 변수 예시
```bash
vpc_id                = "vpc-xxxxxxx"
pub_subnet_id         = "subnet-yyyyyyy"
key_name              = "my-keypair"
boundary_scope_id     = "global"
boundary_prj_name     = "demo-project"
ssh_private_key       = file("~/.ssh/my-key.pem")
ssh_username          = "ubuntu"
```
 