# ArgoCD — the GitOps engine. Terraform BOOTSTRAPS it here; from Phase 3 onward
# ArgoCD itself (via an app-of-apps in the gitops/ folder) manages the retail app
# and the observability stack. That bootstrap-then-GitOps handoff is the pattern
# to be able to draw on a whiteboard: Terraform owns infra + the GitOps engine,
# Git owns everything that runs on top.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    # ALB will terminate TLS in Phase 5, so the server runs HTTP behind it.
    configs = {
      params = {
        "server.insecure" = true
      }
    }
    # Default ClusterIP service; we reach the UI via port-forward until the
    # Ingress goes in. Kept lean (no HA) for a learning cluster.
  })]
}
