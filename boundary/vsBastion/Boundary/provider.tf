terraform {
  required_providers {
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.102.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.85.0"
    }
  }
}

data "hcp_boundary_cluster" "boundary_cluster" {
  cluster_id = var.boundary_cluster
}

provider "boundary" {
  addr                   = data.hcp_boundary_cluster.boundary_cluster.cluster_url
  auth_method_login_name = var.boundary_admin_id
  auth_method_password   = var.boundary_admin_password
}