variable "sns_email" {
  description = "Email address for SNS notifications"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region to deploy the resources"
  type        = string
  default     = "eu-central-1"
}

variable "lambda_bucket" {
  description = "S3 bucket for Lambda code storage"
  type        = string
}

variable "db_password" {
  description = "DB admin password"
  sensitive   = true
}

variable "db_instance_identifier" {
  description = "Identifier of the RDS DB instance to monitor"
  type        = string
}
