resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket        = "lambda-code-bucket-${random_string.suffix.result}"
  force_destroy = true
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
  lower   = true
}
