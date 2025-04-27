resource "aws_lambda_function" "check_db_status" {
  function_name = "CheckRDSStatus"
  handler       = "check_db_status.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.rds_recovery_lambda_exec.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "check_db_status.zip"
  timeout       = 10

  environment {
    variables = {
      DB_INSTANCE_ID = var.db_instance_identifier
      REGION         = var.aws_region
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}

resource "aws_lambda_function" "start_rds_instance" {
  function_name = "StartRDSInstance"
  handler       = "start_rds_instance.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.rds_recovery_lambda_exec.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "start_rds_instance.zip"
  timeout       = 10

  environment {
    variables = {
      DB_INSTANCE_ID = var.db_instance_identifier
      REGION         = var.aws_region
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}

resource "aws_lambda_function" "alert_failure" {
  function_name = "AlertFailure"
  handler       = "alert_failure.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.rds_recovery_lambda_exec.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "alert_failure.zip"
  timeout       = 10

  environment {
    variables = {
      DB_INSTANCE_ID = var.db_instance_identifier
      REGION         = var.aws_region
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}

resource "aws_lambda_function" "poll_rds_alarm_lambda" {
  function_name = "PollRDSAlarmLambda"
  role          = aws_iam_role.rds_recovery_lambda_exec.arn
  handler       = "poll_rds_alarm_lambda.lambda_handler"
  runtime       = "python3.9"

  s3_bucket = var.lambda_bucket
  s3_key    = "poll_rds_alarm_lambda.zip"
  timeout   = 10

  environment {
    variables = {
      ALARM_NAME = aws_cloudwatch_metric_alarm.rds_connection_alarm.alarm_name
      SFN_ARN    = aws_sfn_state_machine.rds_recovery_sfn.arn
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}

