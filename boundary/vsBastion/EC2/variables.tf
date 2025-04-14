variable "boundary_cluster" {
  type        = string
  description = "HCP Boundary 클러스터 이름 또는 설명"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "배포 환경 (예: dev, staging, prod)"
}

variable "boundary_admin_id" {
  type        = string
  description = "Boundary 관리자 로그인 ID"
}

variable "boundary_admin_password" {
  type        = string
  description = "Boundary 관리자 비밀번호"
  sensitive   = true
}

variable "vpc_id" {
  type        = string
  description = "EC2 인스턴스를 생성할 VPC ID"
}

variable "pub_subnet_id" {
  type        = string
  description = "EC2 인스턴스를 생성할 퍼블릭 서브넷 ID"
}

variable "key_name" {
  type        = string
  description = "EC2 인스턴스에 접근할 SSH 키페어 이름"
}

variable "boundary_prj_name" {
  type        = string
  description = "Boundary 프로젝트 이름"
}

variable "boundary_scope_id" {
  type        = string
  description = "Boundary 내의 상위 스코프 ID (예: org의 ID)"
}

variable "private_key_path" {
  type        = string
  description = "로컬에서 사용할 SSH 프라이빗 키의 파일 경로"
}

variable "ssh_user" {
  type        = string
  description = "SSH 접속 시 사용할 사용자 이름 (예: ubuntu, ec2-user 등)"
}