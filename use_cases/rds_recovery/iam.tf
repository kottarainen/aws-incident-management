resource "aws_iam_role" "rds_recovery_lambda_exec" {
  name = "rds-recovery-lambda-exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      },
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        },
        Sid = "StepFunctionAssume"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_recovery_policy" {
  name = "rds-recovery-policy"
  role = aws_iam_role.rds_recovery_lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:StartDBInstance"
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
          "cloudwatch:DescribeAlarms",
          "states:StartExecution"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = [
          aws_lambda_function.check_db_status.arn,
          aws_lambda_function.start_rds_instance.arn,
          aws_lambda_function.alert_failure.arn
        ]
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
