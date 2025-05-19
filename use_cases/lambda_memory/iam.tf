resource "aws_iam_role" "stepfn_lambda_memory_exec" {
  name = "stepfn-lambda-memory-exec"

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

resource "aws_iam_role_policy" "stepfn_lambda_memory_exec_policy" {
  name = "stepfn-lambda-memory-policy"
  role = aws_iam_role.stepfn_lambda_memory_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect = "Allow",
      Action = [
        "lambda:InvokeFunction"
      ],
      Resource = [
        aws_lambda_function.check_memory_lambda.arn,
        aws_lambda_function.update_memory_lambda.arn,
        aws_lambda_function.log_result_lambda.arn,
        aws_lambda_function.notify_admin_lambda.arn
      ]
    },
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
