# Pull the VPC layer's outputs. This is the `terraform_remote_state` pattern:
# the cluster layer never re-declares the VPC, it READS the network layer's state
# from the same S3 bucket. Decoupling like this is exactly what lets us destroy
# and rebuild the cluster without touching the network — and it's a guaranteed
# interview topic.
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "platform/network/terraform.tfstate"
    region = var.region
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # --- API access ----------------------------------------------------------
  # Public endpoint so you can kubectl from your laptop. In real prod you'd lock
  # endpoint_public_access_cidrs down to office/VPN ranges (or go private-only
  # with a bastion) — note that as the hardening step.
  endpoint_public_access = true

  # Access entries are the MODERN replacement for the old aws-auth ConfigMap.
  # "API" mode = access managed purely through EKS access-entry APIs (no configmap).
  # enable_cluster_creator_admin_permissions grants the identity running terraform
  # cluster-admin via an access entry, so `kubectl` works immediately after apply.
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  # --- Networking ----------------------------------------------------------
  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets

  # --- Core managed addons -------------------------------------------------
  # before_compute = true installs the CNI and Pod Identity Agent BEFORE nodes
  # join, so pods can get IPs/credentials the moment they schedule.
  addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true }
  }

  # --- System / platform node group ---------------------------------------
  # Small, fixed on-demand group that hosts cluster-critical platform pods
  # (CoreDNS, Karpenter, ArgoCD, controllers). APPLICATION pods get scheduled
  # onto Karpenter-provisioned nodes (Phase 2) instead. AL2023 is the current
  # default EKS AMI family.
  eks_managed_node_groups = {
    system = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = [var.system_node_instance_type]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = { role = "system" }
    }
  }

  # Tag the node security group for Karpenter discovery (used in Phase 2).
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  # Control-plane logging: kept lean for cost. `api` + `authenticator` are
  # low-volume and useful; add "audit" when you actually need it (it's the
  # chatty/expensive one in CloudWatch).
  enabled_log_types = ["api", "authenticator"]

  # NOTE: create_kms_key (default true) gives you envelope encryption of
  # Kubernetes secrets out of the box, and enable_irsa (default true) creates the
  # OIDC provider so IRSA is available later for the Pod-Identity-vs-IRSA contrast.

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}
