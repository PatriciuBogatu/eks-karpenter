variable "project" {
  description = "Project name, used for tagging."
  type        = string
  default     = "eks-retail"
}

variable "region" {
  description = "AWS region for all resources. Frankfurt is the closest low-latency region for Romania."
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform remote state. MUST match backend.hcl."
  type        = string
  default     = "patriciu-eks-retail-tfstate"
}
