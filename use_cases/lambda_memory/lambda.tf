resource "aws_iam_role" "lambda_exec" {
  name = "oom-remediation-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "oom-remediation-policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect = "Allow",
        Action = [
          "s3:PutBucketAcl",
          "s3:GetBucketAcl",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:StartQuery",
          "logs:GetQueryResults"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = "arn:aws:sns:eu-central-1:${data.aws_caller_identity.current.account_id}:incident-alerts-topic"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = "arn:aws:dynamodb:eu-central-1:${data.aws_caller_identity.current.account_id}:table/incident-audit-log"
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration"
        ],
        Resource = "arn:aws:lambda:eu-central-1:${data.aws_caller_identity.current.account_id}:function:${var.test_lambda_name}"

      }
    ]
  })
}

resource "aws_lambda_function" "increase_memory_lambda" {
  function_name = "IncreaseMemoryLambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "increase_memory_lambda.lambda_handler"
  runtime       = "python3.9"

  s3_bucket = var.lambda_bucket
  s3_key    = "increase_memory_lambda.zip"
  timeout   = 20

  environment {
    variables = {
      AUDIT_LOG_TABLE = var.audit_log_table_name
      SNS_TOPIC_ARN   = var.sns_topic_arn
      TARGET_LAMBDA   = "MemoryTestLambda"
    }
  }
}

data "aws_caller_identity" "current" {}
