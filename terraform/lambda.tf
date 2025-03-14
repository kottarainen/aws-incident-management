resource "aws_lambda_function" "restart_ec2" {
  function_name = "RestartEC2Lambda"
  runtime       = "python3.9"
  handler       = "restart_ec2_lambda.lambda_handler"
  role          = aws_iam_role.lambda_exec_role.arn

  s3_bucket = aws_s3_bucket.lambda_code_bucket.id
  s3_key    = "restart_ec2_lambda.zip"

  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      REGION = var.aws_region
    }
  }
}
