# HCP Vault Secrets + EKS (VSO) 연동 가이드

📦 목적
- HCP Vault Secrets와 Vault Secret Operator를 연동하여 EKS의 Secret 관리하기
- Terraform Code로 HCP Vault Secrets부터 EKS Secret 연동까지 관리

🎯 HCP Vault Secrets VS Vault 
- HCP Vault Secrets:
    - Secret 저장 전용 경량 서비스 
    - HCP에서 완전 관리형 (설치 불필요)
    - Terraform, CI/CD에 빠르게 연동 가능
    - 간단한 용도에 최적, 저렴한 비용

- Vault (특히 OSS/Enterprise):
    - 전체 보안 플랫폼 (K/V + 동적 Secret + PKI 등)
    - 직접 설치 또는 HCP에서 관리형으로 사용 가능
    - IAM(AWS), MFA, RBAC 등 보안 기능 다양
    - 복잡한 시크릿 정책과 통합 환경에 적합

📐 연동절차

1. HCP Vault Secrets 생성하기
- **HCP Organization과 Project는 미리 만들어져 있음**
- **EKS에 Vault Secret Operator가 배포되어 있음**
- 만약 권한관리를 위하면 다음의 링크 참조
  - [iam_policy](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/resources/vault_secrets_app_iam_policy)
  - [iam_binding](https://registry.terraform.io/providers/hashicorp/hcp/latest/docs/resources/vault_secrets_app_iam_binding)

```bash
resource "hcp_vault_secrets_app" "hcp_secrets_app" {
  app_name   = "secretsApp"
}

resource "hcp_vault_secrets_secret" "secrets" {
  for_each     = var.secrets
  app_name     = hcp_vault_secrets_app.hcp_secrets_app.app_name
  secret_name  = each.key
  secret_value = each.value
}
```

2. Kubernetes Manifest 생성하기
- HCP Vault Secrets에 접근 가능한 계정의 Client ID와 Secret을 Kubernetes Secret으로 생성
```bash
apiVersion: v1
kind: Secret
metadata:
  name: vso-demo-sp
  namespace: ops
type: Opaque
stringData:
  clientID: ${HCP_CLIENT_ID}
  clientSecret: ${HCP_CLIENT_SECRET}
```

- 생성한 Kubernetes Secret와 HCP ORG, PRJ ID를 넣은 custom resource 생성
```bash
apiVersion: secrets.hashicorp.com/v1beta1
kind: HCPAuth
metadata:
  name: hcp-auth
  namespace: ops
spec:
  organizationID: ${ORGANIZATION_ID}
  projectID: ${PROJECT_ID}
  servicePrincipal:
    secretRef: vso-demo-sp
```

- Application(deployment등)에서 사용 할 수 있게 Kubernetes Secret 생성 및 동기화
```bash
apiVersion: secrets.hashicorp.com/v1beta1
kind: HCPVaultSecretsApp
metadata:
  name: vso-app
  namespace: ops
spec:
  appName: secretsApp
  hcpAuthRef: hcp-auth
  refreshAfter: 60s
  destination:
    create: true
    labels:
      env: "hcp-vault-secrets"    
    name: cis-gw-main-secret
    overwrite: true
```

3. 결과 확인

- HCP Vault Secrets의 데이터 값 기준으로 Sync 진행 중
```bash
Metadata:                                                                                          Creation Timestamp:  2025-04-21T06:04:49Z                                                        Finalizers:                                                                                        hcpvaultsecretsapp.secrets.hashicorp.com/finalizer                                             Generation:        2                                                                             Resource Version:  88654326                                                                      UID:               bdccb0ab-80f1-4b15-ad44-0dc339b1333e                                        Spec:                                                                                              App Name:  secretsApp                                                                            Destination:                                                                                       Create:  true                                                                                    Labels:                                                                                            Env:      hcp-vault-secrets                                                                    Name:       cis-gw-main-secret                                                                   Overwrite:  true
    Transformation:
  Hcp Auth Ref:   hcp-auth
  Refresh After:  60s
Status:
  Last Generation:  2
Events:
  Type    Reason         Age                   From                Message
  ----    ------         ----                  ----                -------
  Normal  SecretSynced   35m                   HCPVaultSecretsApp  Secret synced
  Normal  SecretRotated  35m                   HCPVaultSecretsApp  Secret synced
```

- HCP Vault Secrets의 데이터 값 기준으로 생성된 Kubernetes Secret
```bash
Name:         cis-gw-main-secret
Namespace:    ops
Labels:       app.kubernetes.io/component=secret-sync
              app.kubernetes.io/managed-by=hashicorp-vso
              app.kubernetes.io/name=vault-secrets-operator
              env=hcp-vault-secrets
Annotations:  <none>

Type:  Opaque

Data
====
HCP_VAULT_URL:                 124 bytes
MEGAZONE_EXPENSE_CLAIM_URL:    44 bytes
GITLAB_URL:                    31 bytes
GRAFANA_URL:                   31 bytes
HASHICORP_DISCUSS_URL:         30 bytes
...
```