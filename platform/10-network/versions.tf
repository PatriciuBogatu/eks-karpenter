terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # resolves to latest 6.x; VPC module v6 needs >= 6.28
    }
  }

  backend "s3" {
    key = "platform/network/terraform.tfstate"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Layer     = "platform/network"
    }
  }
}
