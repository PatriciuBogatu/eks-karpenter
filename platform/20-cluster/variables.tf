variable "project" {
  type    = string
  default = "eks-retail"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  type    = string
  default = "eks-retail"
}

variable "kubernetes_version" {
  description = "EKS control plane version. 1.33 is current as of 2026."
  type        = string
  default     = "1.33"
}

# Remote-state lookup needs the bucket explicitly (a data source can't read
# backend.hcl). Keep these in sync with backend.hcl.
variable "state_bucket" {
  type    = string
  default = "patriciu-eks-retail-tfstate"
}

variable "system_node_instance_type" {
  description = "Instance type for the system/platform managed node group."
  type        = string
  default     = "t3.large"
}
