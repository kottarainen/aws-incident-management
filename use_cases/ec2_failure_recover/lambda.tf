resource "aws_lambda_function" "recover_ec2_instance" {
  function_name = "RecoverEC2InstanceLambda"
  s3_bucket     = var.lambda_bucket
  s3_key        = "recover_ec2_lambda.zip"
  handler       = "recover_ec2_lambda.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      REGION          = var.aws_region
      SNS_TOPIC_ARN   = var.sns_topic_arn
      AUDIT_LOG_TABLE = var.audit_log_table_name
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recover_ec2_instance.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_instance_state_change.arn
}
