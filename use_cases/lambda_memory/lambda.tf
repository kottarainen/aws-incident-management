data "aws_caller_identity" "current" {}

resource "aws_lambda_function" "check_memory_lambda" {
  function_name = "CheckMemoryLambda"
  role          = aws_iam_role.stepfn_lambda_memory_exec.arn
  handler       = "check_memory_lambda.lambda_handler"
  runtime       = "python3.9"

  s3_bucket = var.lambda_bucket
  s3_key    = "check_memory_lambda.zip"
  timeout   = 10

  environment {
    variables = {
      TARGET_LAMBDA = var.test_lambda_name
    }
  }
}

resource "aws_lambda_function" "update_memory_lambda" {
  function_name = "UpdateMemoryLambda"
  role          = aws_iam_role.stepfn_lambda_memory_exec.arn
  handler       = "update_memory_lambda.lambda_handler"
  runtime       = "python3.9"

  s3_bucket = var.lambda_bucket
  s3_key    = "update_memory_lambda.zip"
  timeout   = 10

  environment {
    variables = {
      TARGET_LAMBDA = var.test_lambda_name
    }
  }
}

resource "aws_lambda_function" "log_result_lambda" {
  function_name = "LogResultLambda"
  role          = aws_iam_role.stepfn_lambda_memory_exec.arn
  handler       = "log_result_lambda.lambda_handler"
  runtime       = "python3.9"

  s3_bucket = var.lambda_bucket
  s3_key    = "log_result_lambda.zip"
  timeout   = 10

  environment {
    variables = {
      AUDIT_LOG_TABLE = var.audit_log_table_name
    }
  }
}

resource "aws_lambda_function" "notify_admin_lambda" {
  function_name = "NotifyAdminLambda"
  role          = aws_iam_role.stepfn_lambda_memory_exec.arn
  handler       = "notify_lambda.lambda_handler"
  runtime       = "python3.9"

  s3_bucket = var.lambda_bucket
  s3_key    = "notify_lambda.zip"
  timeout   = 10

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}
