resource "aws_lambda_function" "restart_ec2" {
  function_name = "RestartEC2Lambda"
  runtime       = "python3.9"
  handler       = "restart_ec2_lambda.lambda_handler"
  role          = aws_iam_role.lambda_exec_role.arn

  s3_bucket = aws_s3_bucket.lambda_code_bucket.id
  s3_key    = aws_s3_object.lambda_code.key

  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      REGION = var.aws_region
    }
  }
}

resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code_bucket.id
  key    = "restart_ec2_lambda.zip"
  source = "../lambda_functions/restart_ec2_lambda.zip" 
  etag   = filemd5("../lambda_functions/restart_ec2_lambda.zip")
}
