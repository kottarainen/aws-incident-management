resource "aws_s3_bucket" "monitored_bucket" {
  bucket = "monitored-s3-bucket-${random_string.suffix.result}"
  force_destroy = true
  tags = {
    Name        = "MonitoredS3Bucket"
    Environment = "ThesisMonitoring"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket_public_access_block" "monitored_bucket_block" {
  bucket = aws_s3_bucket.monitored_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.monitored_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
