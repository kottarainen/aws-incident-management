resource "aws_iam_role" "memory_test_lambda_exec" {
  name = "memory-test-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "memory_test_lambda_policy" {
  name = "memory-test-policy"
  role = aws_iam_role.memory_test_lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "memory_test_lambda" {
  function_name = "MemoryTestLambda"
  handler       = "memory_test_lambda.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.memory_test_lambda_exec.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "memory_test_lambda.zip"
  timeout       = 10
  memory_size   = 128

  environment {
    variables = {
      REGION = var.aws_region
    }
  }
}

resource "aws_cloudwatch_log_group" "memory_test_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.memory_test_lambda.function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_metric_filter" "memory_error_filter" {
  name           = "MemoryErrorFilter"
  log_group_name = aws_cloudwatch_log_group.memory_test_lambda_logs.name

  pattern = "OutOfMemoryError"

  metric_transformation {
    name      = "MemoryErrorCount"
    namespace = "LambdaMemoryMonitoring"
    value     = "1"
  }
}

output "memory_test_lambda_name" {
  value = aws_lambda_function.memory_test_lambda.function_name
}
