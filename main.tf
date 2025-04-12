terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "monitored_environment" {
  source = "./monitored_environment"
  sns_email     = var.sns_email
  lambda_bucket = var.lambda_bucket
  sns_topic_arn = module.monitored_environment.incident_alerts_topic_arn
}

module "use_case_high_cpu_restart" {
  source    = "./use_cases/high_cpu_restart"
  sns_email     = var.sns_email
  lambda_bucket = var.lambda_bucket
  sns_topic_arn = module.monitored_environment.incident_alerts_topic_arn
}

module "use_case_s3_public_access" {
  source = "./use_cases/s3_public_access_revoke"
  sns_email     = var.sns_email
  lambda_bucket = var.lambda_bucket
  sns_topic_arn = module.monitored_environment.incident_alerts_topic_arn
}
