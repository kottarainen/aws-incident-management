resource "aws_lambda_function" "network_alarm_handler" {
  function_name = "NetworkAlarmHandler"
  handler       = "network_alarm_handler.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.network_lambda_exec.arn
  timeout       = 10
  memory_size   = 128

  s3_bucket = var.lambda_bucket
  s3_key    = "network_alarm_handler.zip"

  environment {
    variables = {
      AUDIT_LOG_TABLE = var.audit_log_table_name
      SNS_TOPIC_ARN   = var.sns_topic_arn
      INSTANCE_ID     = var.instance_id
    }
  }
}

resource "aws_iam_role" "network_lambda_exec" {
  name = "network-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "network_lambda_policy" {
  name = "network-lambda-policy"
  role = aws_iam_role.network_lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ],
        Resource = "arn:aws:dynamodb:eu-central-1:${data.aws_caller_identity.current.account_id}:table/incident-audit-log"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = var.sns_topic_arn
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
