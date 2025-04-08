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