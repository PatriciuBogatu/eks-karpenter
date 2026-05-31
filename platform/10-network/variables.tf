variable "project" {
  type    = string
  default = "eks-retail"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  description = "Used for subnet tags so the AWS LB Controller and Karpenter can discover them."
  type        = string
  default     = "eks-retail"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of AZs to spread across. 3 is the standard prod choice."
  type        = number
  default     = 3
}
