data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Private subnets are /19 (≈8k IPs each). They're deliberately large because the
  # AWS VPC CNI hands each pod a real VPC IP out of the SUBNET — small subnets =
  # "insufficient IPs" pod-scheduling failures, a classic EKS gotcha. Public
  # subnets are small /24s (just for the NAT gateway + ALBs).
  private_subnets = [for k in range(var.az_count) : cidrsubnet(var.vpc_cidr, 3, k)]
  public_subnets  = [for k in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 96 + k)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  # Single NAT gateway: cheapest option for a dev / build-and-destroy loop.
  # PROD would set single_nat_gateway = false (one per AZ) so losing an AZ
  # doesn't take out egress for everything — that's the HA-vs-cost tradeoff to
  # name in an interview.
  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet discovery tags — these are what make EKS networking "just work":
  #  - public/elb            -> ALBs/NLBs for internet-facing Ingress land here
  #  - private/internal-elb  -> internal load balancers land here
  #  - karpenter.sh/discovery -> Karpenter (Phase 2) finds where to launch nodes
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery"          = var.cluster_name
  }
}
