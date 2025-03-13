resource "aws_lambda_function" "restart_ec2" {
  function_name    = "RestartEC2Lambda"
  runtime         = "python3.9"
  handler         = "restart_ec2_lambda.lambda_handler"
  filename        = "${path.module}/lambda_functions/restart_ec2_lambda.zip" 
  role            = aws_iam_role.lambda_exec.arn
  timeout         = 10

  source_code_hash = filebase64sha256("${path.module}/lambda_functions/restart_ec2_lambda.zip")

  environment {
    variables = {
      REGION = var.aws_region
    }
  }
}
