output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  description = "Cluster (control plane) security group ID."
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Node security group ID — tagged for Karpenter discovery."
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN (for IRSA, if/when used)."
  value       = module.eks.oidc_provider_arn
}

output "region" {
  value = var.region
}

output "update_kubeconfig_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
