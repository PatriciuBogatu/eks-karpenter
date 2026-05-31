# External Secrets Operator (ESO) syncs AWS Secrets Manager secrets into native
# Kubernetes Secrets. Used in Phase 4 to pull DB credentials for the app. Scoped
# to secrets under the "eks-retail" prefix (least privilege).
module "external_secrets_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                                  = "${local.cluster_name}-external-secrets"
  attach_external_secrets_policy        = true
  external_secrets_create_permission    = false # read-only; we don't let it create secrets
  external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:eks-retail/*"]

  associations = {
    this = {
      cluster_name    = local.cluster_name
      namespace       = "external-secrets"
      service_account = "external-secrets"
    }
  }
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    installCRDs = true
    serviceAccount = {
      create = true
      name   = "external-secrets"
    }
  })]

  # AWS LBC registers a cluster-wide mutating webhook on every Service
  # (failurePolicy: Fail). ESO creates Services on install; if the LBC webhook
  # has no ready endpoints yet the call fails. Order ESO after LBC.
  depends_on = [
    module.external_secrets_pod_identity,
    helm_release.aws_lbc,
  ]
}
