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
 
## Bastion vs. Boundary 간단 비교

### Bastion Host와 Boundary의 차이점 간단 비교
📌  접근 방식
Bastion: SSH 키를 이용한 직접 접속 방식을 사용
Boundary: 중앙에서 발급된 세션을 통해 간접적으로 리소스에 연결
📌  인증 방식
Bastion: 키 기반 인증에 의존하는 반면
Boundary: OIDC, LDAP 같은 외부 인증 시스템과 연동할 수 있어 더 유연하고 안전한 사용자 인증이 가능
📌  접근 제어
Bastion: 네트워크나 보안 그룹 수준에서 접근 제어
Boundary: RBAC을 통해 리소스 단위로 세세한 권한을 부여
📌  감사 및 로깅
Bastion: SSH 로그나 CloudTrail 등으로 간접적인 감사
Boundary: 세션 생성/종료, 사용자 식별 등 상세한 로깅 기능을 기본으로 제공
📌  보안성 및 운영 효율
Bastion: 키 유출에 취약하고 수동 관리가 많음
Boundary: 키 공유가 없고 자동화된 세션 관리로 운영 효율을 높힘

### Terraform으로 구성 전략

Terraform 코드는 두 개의 Workspace로 나누어 구성했습니다.

#### 🛠 첫 번째 Workspace
: Boundary와 Worker를 자동으로 구성하는 코드입니다.
Boundary Enterprise(HCP) 환경 기준으로, Worker를 EC2에 배포하고 Controller와 통신할 수 있도록 설정합니다. Vault처럼 토큰 발급 방식이 필요하기 때문에 약간의 로컬 스크립트 연동도 포함했습니다.

#### 🛠 두 번째 Workspace
: 실제로 Boundary의 Target, Credential Store, Host Catalog 등을 구성합니다.
EC2와 같은 리소스가 생성된 이후 자동으로 Target으로 등록되며, SSH 접속을 위한 Key 또는 Username/Password 등의 Credential도 함께 설정됩니다.

#### 왜 분리했을까?
Boundary Target은 리소스(예: EC2) 생성 이후의 정보(IP 등)를 참조해야 하므로, 한 Workspace에서 모두 처리하면 의존성 충돌이나 불필요한 재적용이 생길 수 있습니다.
따라서 리소스 생성과 Boundary Target 등록을 분리하여 구성함으로써, 관리성과 재사용성을 높이고 실행 횟수를 줄이는 효과를 기대할 수 있습니다.
