variable "project" {
  type    = string
  default = "eks-retail"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "state_bucket" {
  type    = string
  default = "patriciu-eks-retail-tfstate"
}

# --- Chart versions ----------------------------------------------------------
# Pinning charts is best practice (reproducible rebuilds). The two below are
# verified-current; bump with `helm search repo <repo>/<chart> --versions`.
# The ESO + ArgoCD pins are left null (= latest) to avoid a stale pin failing
# your first apply — set them to the version your apply resolves, for reproducibility.
variable "karpenter_chart_version" {
  type    = string
  default = "1.11.1"
}

variable "aws_lbc_chart_version" {
  type    = string
  default = "1.13.1" # chart 1.13.x -> controller app v2.13.x
}

variable "external_dns_chart_version" {
  type    = string
  default = "1.20.0"
}

variable "external_secrets_chart_version" {
  type    = string
  default = null
}

variable "argocd_chart_version" {
  type    = string
  default = null
}

# Karpenter provisions nodes from these instance families/sizes. Kept to modern
# generations (>4) and general-purpose categories for the retail app.
variable "karpenter_instance_categories" {
  type    = list(string)
  default = ["c", "m", "r"]
}
