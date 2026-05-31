# The remote-state bucket. This lives in the PERSISTENT layer: you create it
# once and never destroy it (destroying it would orphan every other layer's
# state). Versioning is on so a bad apply can be recovered; encryption + a hard
# public-access block are table stakes for anything holding state.

resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  # Safety net: refuse to destroy a bucket that still has objects in it.
  # If you ever truly want it gone, set this to false first, then destroy.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3, free. Swap to aws:kms if you want a CMK.
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Keep state-file history from growing forever: expire old, non-current versions.
resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    id     = "expire-noncurrent-state-versions"
    status = "Enabled"
    filter {} # apply to whole bucket
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
