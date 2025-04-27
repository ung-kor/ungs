terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.104.0"
    }
  }
}

provider "hcp" {
  # Configuration options
}

provider "kubernetes" {
  config_path = "~/.kube/config" 
}

resource "hcp_vault_secrets_app" "hcp_secrets_app" {
  app_name   = "secretsApp"
}

resource "hcp_vault_secrets_secret" "secrets" {
  for_each     = var.secrets
  app_name     = hcp_vault_secrets_app.hcp_secrets_app.app_name
  secret_name  = each.key
  secret_value = each.value
}

resource "kubernetes_manifest" "HCPAuthSecret" {
  manifest = yamldecode(templatefile("${path.module}/yamlTemplate/secret.tmpl", {
    HCP_CLIENT_ID     = var.client_id
    HCP_CLIENT_SECRET = var.client_secret
  }))
}

resource "kubernetes_manifest" "HCPVaultSecretsApp" {
  manifest = yamldecode(templatefile("${path.module}/yamlTemplate/HCPVaultSecretsApp.tmpl", {}))
}

resource "kubernetes_manifest" "HCPAuth" {
  manifest = yamldecode(templatefile("${path.module}/yamlTemplate/HCPAuth.tmpl", {
    ORGANIZATION_ID = var.organization_id
    PROJECT_ID      = var.project_id
  }))
}