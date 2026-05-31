# The kubernetes + helm providers authenticate to the cluster using the AWS CLI
# token exec plugin — the same mechanism `aws eks update-kubeconfig` sets up. We
# read the cluster endpoint + CA from the CLUSTER layer's remote state. Because
# the cluster already exists in its own apply, there's no provider-before-resource
# chicken-and-egg here (that's exactly why addons is a separate layer).

locals {
  cluster_name     = data.terraform_remote_state.cluster.outputs.cluster_name
  cluster_endpoint = data.terraform_remote_state.cluster.outputs.cluster_endpoint
  cluster_ca       = data.terraform_remote_state.cluster.outputs.cluster_certificate_authority_data
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = base64decode(local.cluster_ca)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
  }
}

provider "helm" {
  # Isolate from the user's global ~/helm/repositories.yaml so a broken global
  # repo entry (e.g. the deprecated bitnami index) can't block our applies.
  repository_config_path = "${path.module}/.helm/repositories.yaml"
  repository_cache       = "${path.module}/.helm/cache"

  kubernetes {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = base64decode(local.cluster_ca)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
    }
  }
}
