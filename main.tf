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
  source                 = "./monitored_environment"
  sns_email              = var.sns_email
  lambda_bucket          = var.lambda_bucket
  sns_topic_arn          = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name  = module.monitored_environment.monitored_bucket_name
  db_password            = var.db_password
  db_instance_identifier = var.db_instance_identifier
}

module "use_case_high_cpu_restart" {
  source                = "./use_cases/high_cpu_restart"
  sns_email             = var.sns_email
  lambda_bucket         = var.lambda_bucket
  sns_topic_arn         = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name = module.monitored_environment.monitored_bucket_name
  audit_log_table_name  = module.monitored_environment.audit_log_table_name
}

module "use_case_s3_public_access" {
  source                = "./use_cases/s3_public_access_revoke"
  sns_email             = var.sns_email
  lambda_bucket         = var.lambda_bucket
  sns_topic_arn         = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name = module.monitored_environment.monitored_bucket_name
  audit_log_table_name  = module.monitored_environment.audit_log_table_name
}

module "use_case_ssh_ingress" {
  source                = "./use_cases/ssh_ingress_revoke"
  sns_email             = var.sns_email
  lambda_bucket         = var.lambda_bucket
  sns_topic_arn         = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name = module.monitored_environment.monitored_bucket_name
  audit_log_table_name  = module.monitored_environment.audit_log_table_name
}

module "use_case_ec2_failure_recover" {
  source                = "./use_cases/ec2_failure_recover"
  sns_email             = var.sns_email
  lambda_bucket         = var.lambda_bucket
  sns_topic_arn         = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name = module.monitored_environment.monitored_bucket_name
  audit_log_table_name  = module.monitored_environment.audit_log_table_name
}

module "use_case_lambda_memory" {
  source                = "./use_cases/lambda_memory"
  sns_email             = var.sns_email
  lambda_bucket         = var.lambda_bucket
  sns_topic_arn         = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name = module.monitored_environment.monitored_bucket_name
  audit_log_table_name  = module.monitored_environment.audit_log_table_name
  test_lambda_name      = "MemoryTestLambda"
}

module "use_case_rds_recovery" {
  source                 = "./use_cases/rds_recovery"
  sns_email              = var.sns_email
  lambda_bucket          = var.lambda_bucket
  sns_topic_arn          = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name  = module.monitored_environment.monitored_bucket_name
  audit_log_table_name   = module.monitored_environment.audit_log_table_name
  db_instance_identifier = var.db_instance_identifier
}

module "use_case_network_monitoring" {
  source                = "./use_cases/network_monitoring"
  sns_email             = var.sns_email
  lambda_bucket         = var.lambda_bucket
  sns_topic_arn         = module.monitored_environment.incident_alerts_topic_arn
  monitored_bucket_name = module.monitored_environment.monitored_bucket_name
  audit_log_table_name  = module.monitored_environment.audit_log_table_name
  db_instance_identifier = var.db_instance_identifier
  instance_id           = var.instance_id
}
