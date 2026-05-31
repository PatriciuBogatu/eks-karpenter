# Pod Identity role for the AWS Load Balancer Controller. The eks-pod-identity
# module bundles the maintained LBC IAM policy (attach_aws_lb_controller_policy)
# AND creates the Pod Identity association in one shot — no OIDC, no IRSA.
module "lbc_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0"

  name                            = "${local.cluster_name}-aws-lbc"
  attach_aws_lb_controller_policy = true

  associations = {
    this = {
      cluster_name    = local.cluster_name
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
    }
  }
}

# The controller watches Ingress (ingressClassName: alb) and Service type=LoadBalancer
# and provisions ALBs/NLBs. It needs clusterName + region + vpcId.
resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.aws_lbc_chart_version
  namespace  = "kube-system"
  wait       = true

  values = [yamlencode({
    clusterName = local.cluster_name
    region      = var.region
    vpcId       = local.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller" # matches the Pod Identity association
    }
  })]

  depends_on = [module.lbc_pod_identity]
}
