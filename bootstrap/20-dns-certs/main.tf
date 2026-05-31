# The hosted zone already exists (created when you registered patriciu.click in
# Route53), so we only LOOK IT UP — we don't manage it. This keeps the zone and
# its NS delegation safe from `terraform destroy`.
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# One wildcard cert covers every app: ui.patriciu.click, argocd.patriciu.click,
# grafana.patriciu.click, etc. SAN includes the apex so the bare domain works too.
#
# IMPORTANT: this cert is REGIONAL and lives in eu-central-1 because it terminates
# on an ALB (Application Load Balancer), which is a regional resource. (Only
# CloudFront requires certs in us-east-1.) The ALB controller in the platform
# layer will reference this ARN via remote state.
resource "aws_acm_certificate" "wildcard" {
  domain_name               = "*.${var.domain_name}"
  subject_alternative_names = [var.domain_name]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Write the DNS validation record(s) into the hosted zone.
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = data.aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Block until ACM sees the record and marks the cert ISSUED. Doing this once in
# the persistent layer means cluster rebuilds reuse an already-valid cert.
resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = aws_acm_certificate.wildcard.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
