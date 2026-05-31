variable "project" {
  type    = string
  default = "eks-retail"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "domain_name" {
  description = "Apex domain you registered in Route53 (hosted zone must already exist)."
  type        = string
  default     = "patriciu.click"
}
