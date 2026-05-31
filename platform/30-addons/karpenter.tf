# The Karpenter submodule creates EVERYTHING on the AWS side:
#  - controller IAM role + scoped policy, wired via Pod Identity (no IRSA/OIDC)
#  - a Pod Identity association for the "karpenter" SA in kube-system
#  - the node IAM role (Karpenter builds the instance profile from it)
#  - an access entry so Karpenter-launched nodes can join the cluster
#  - the SQS queue + EventBridge rules for spot-interruption handling
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 21.0"

  cluster_name = local.cluster_name

  # Pod Identity is the only mechanism in module v21 (no toggle); create the
  # SA association explicitly.
  create_pod_identity_association = true

  # v21 controller policy exceeds the 6144-char managed-policy quota. Attach it
  # as an inline role policy instead (10240-char limit). Module-documented fix.
  enable_inline_policy = true

  # Give Karpenter nodes SSM access (handy for debugging via Session Manager).
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

# Karpenter controller, installed from the public ECR OCI registry. It runs on
# the SYSTEM managed node group (nodeSelector role=system) — Karpenter can't
# provision the node it runs on, so it must live on the fixed MNG.
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_chart_version
  namespace        = "kube-system"
  create_namespace = false
  wait             = true

  values = [yamlencode({
    serviceAccount = {
      # Must match the Pod Identity association the submodule created.
      name = module.karpenter.service_account
    }
    settings = {
      clusterName       = local.cluster_name
      clusterEndpoint   = local.cluster_endpoint
      interruptionQueue = module.karpenter.queue_name
    }
    # Pin the controller to the system node group.
    nodeSelector = { role = "system" }
    replicas     = 1
    controller = {
      resources = {
        requests = { cpu = "0.5", memory = "512Mi" }
        limits   = { cpu = "1", memory = "1Gi" }
      }
    }
  })]

  depends_on = [module.karpenter]
}

# --- NodePool + EC2NodeClass (Karpenter CRs) ---------------------------------
# These are Kubernetes custom resources, not AWS resources, and they depend on
# Karpenter's CRDs existing first. Rather than fight Terraform's kubernetes_manifest
# (which wants the CRD at PLAN time), we render them to YAML with the generated
# node-role name injected, and apply them with `kubectl` after the Helm install
# (see the Makefile `karpenter-cr` target). This also keeps the YAML visible and
# tweakable — which is exactly what you'll be asked about in an interview.
resource "local_file" "ec2nodeclass" {
  filename = "${path.module}/karpenter/rendered/ec2nodeclass.yaml"
  content = templatefile("${path.module}/karpenter/ec2nodeclass.yaml.tftpl", {
    node_role_name = module.karpenter.node_iam_role_name
    cluster_name   = local.cluster_name
  })
}

resource "local_file" "nodepool" {
  filename = "${path.module}/karpenter/rendered/nodepool.yaml"
  content = templatefile("${path.module}/karpenter/nodepool.yaml.tftpl", {
    instance_categories = var.karpenter_instance_categories
  })
}
