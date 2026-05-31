# ExternalDNS watches Ingresses/Services and creates matching Route53 records in
# YOUR hosted zone, so apps become reachable at <name>.patriciu.click automatically.
# The IAM policy is scoped to just this hosted zone (least privilege).
module "external_dns_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                          = "${local.cluster_name}-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${local.route53_zone_id}"]

  associations = {
    this = {
      cluster_name    = local.cluster_name
      namespace       = "external-dns"
      service_account = "external-dns"
    }
  }
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = var.external_dns_chart_version
  namespace        = "external-dns"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    # Chart 1.20: the bare `provider: aws` string is deprecated; use provider.name.
    provider = { name = "aws" }
    serviceAccount = {
      create = true
      name   = "external-dns"
    }
    # Only manage records under our domain, and tag ownership so this cluster
    # never fights another over the same zone.
    domainFilters = [local.domain_name]
    txtOwnerId    = local.cluster_name
    registry      = "txt"
    policy        = "sync" # create + update + DELETE records (full lifecycle)
    sources       = ["ingress", "service"]
    extraArgs     = ["--aws-zone-type=public"]
  })]

  depends_on = [module.external_dns_pod_identity]
}
