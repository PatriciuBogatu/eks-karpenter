output "karpenter_node_role_name" {
  value = module.karpenter.node_iam_role_name
}

output "karpenter_queue_name" {
  value = module.karpenter.queue_name
}

output "rendered_karpenter_manifests" {
  description = "Apply these after the Helm install: kubectl apply -f <dir>"
  value       = "${path.module}/karpenter/rendered/"
}

output "argocd_admin_password_cmd" {
  description = "Fetch the initial ArgoCD admin password."
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_portforward_cmd" {
  value = "kubectl -n argocd port-forward svc/argocd-server 8080:80"
}
