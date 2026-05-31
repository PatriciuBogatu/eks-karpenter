output "repository_urls" {
  description = "Map of service name -> ECR repo URL (used by CI and Helm values)."
  value       = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}

output "repository_arns" {
  value = { for k, r in aws_ecr_repository.this : k => r.arn }
}
