data "aws_caller_identity" "current" {}

# --- Remote state from the other layers --------------------------------------
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/network/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "cluster" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/cluster/terraform.tfstate"
    region = var.region
  }
}

# Persistent bootstrap layer: hosted zone id + wildcard cert ARN.
data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "bootstrap/dns-certs/terraform.tfstate"
    region = var.region
  }
}

locals {
  account_id      = data.aws_caller_identity.current.account_id
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  route53_zone_id = data.terraform_remote_state.dns.outputs.route53_zone_id
  domain_name     = data.terraform_remote_state.dns.outputs.domain_name
  acm_cert_arn    = data.terraform_remote_state.dns.outputs.acm_certificate_arn
}
