output "acm_certificate_arn" {
  description = "Validated wildcard cert ARN — consumed by the ALB controller / Ingress."
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

output "route53_zone_id" {
  description = "Hosted zone ID — consumed by ExternalDNS."
  value       = data.aws_route53_zone.this.zone_id
}

output "domain_name" {
  value = var.domain_name
}
