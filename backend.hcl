# Shared S3 backend config (partial configuration).
# Every layer EXCEPT 00-state-backend uses this. Each layer sets its own `key`
# in its versions.tf; everything else lives here so we don't repeat ourselves.
#
# Pass it at init time:  terraform init -backend-config=../../backend.hcl
#
# NOTE: the bucket name must be GLOBALLY unique across all of AWS. 
# If `terraform apply` in 00-state-backend tells you the name is taken, pick a new
# one and change it in BOTH places (here and 00-state-backend/terraform.tfvars).

bucket       = "patriciu-eks-retail-tfstate"
region       = "eu-central-1"
encrypt      = true
use_lockfile = true # native S3 state locking (Terraform >= 1.10) — no DynamoDB table needed
