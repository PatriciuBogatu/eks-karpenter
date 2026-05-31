output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state. Put this in backend.hcl."
  value       = aws_s3_bucket.tfstate.id
}

output "state_bucket_arn" {
  value = aws_s3_bucket.tfstate.arn
}

output "region" {
  value = var.region
}
