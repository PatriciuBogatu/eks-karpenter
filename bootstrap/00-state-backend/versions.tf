# This is the ONLY layer that uses LOCAL state. It creates the S3 bucket that
# every other layer stores its state in — so it can't store its own state there
# before the bucket exists (the classic chicken-and-egg). Local state is fine
# here: it's one bucket, you apply it once, and you basically never touch it again.
#
# (Optional, advanced: after the first apply you can add an s3 backend block
#  pointing at the bucket you just made and run `terraform init -migrate-state`.
#  Not necessary — skipping keeps the bootstrap simple.)

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Layer     = "bootstrap/state-backend"
    }
  }
}
