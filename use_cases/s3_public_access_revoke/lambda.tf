resource "aws_iam_role" "lambda_exec_role" {
  name = "s3-revoke-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "s3-revoke-policy"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
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
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = "arn:aws:sns:eu-central-1:${data.aws_caller_identity.current.account_id}:incident-alerts-topic"
      }
    ]
  })
}

resource "aws_lambda_function" "revoke_s3_public_access" {
  function_name = "RevokeS3AccessLambda"
  handler       = "revoke_s3_access_lambda.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  s3_bucket     = var.lambda_bucket
  s3_key        = "revoke_s3_access_lambda.zip"
  memory_size   = 128
  timeout       = 10
  environment {
    variables = {
      REGION        = var.aws_region
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }
}
