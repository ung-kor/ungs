variable "boundary_addr" {
  type        = string
  description = "HCP Boundary 클러스터의 주소 (예: https://boundary-cluster.boundary.hashicorp.cloud)"
}

variable "boundary_cluster_id" {
  type        = string
  description = "HCP Boundary 클러스터 ID"
}

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

variable "private_key_path" {
  type        = string
  description = "로컬에 존재하는 SSH 프라이빗 키 경로"
}