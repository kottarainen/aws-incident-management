resource "aws_lambda_function" "revoke_ssh_access" {
  function_name = "RevokeSSHAccessLambda"
  handler       = "revoke_ssh_lambda.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "revoke_ssh_lambda.zip"

  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      REGION        = var.aws_region
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}
