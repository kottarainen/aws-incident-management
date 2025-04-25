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

variable "sns_topic_arn" {
  description = "ARN of the shared SNS topic for incident alerts"
  type        = string
}

variable "monitored_bucket_name" {
  type = string
}

variable "audit_log_table_name" {
  description = "Name of the DynamoDB audit log table"
  type        = string
}

variable "test_lambda_name" {
  description = "Name of the Lambda function to monitor"
  type        = string
}

