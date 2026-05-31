terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Partial config: bucket/region/encrypt/use_lockfile come from backend.hcl at
  # init time. Only `key` (this layer's path within the bucket) is set here.
  backend "s3" {
    key = "bootstrap/ecr/terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Layer     = "bootstrap/ecr"
    }
  }
}
