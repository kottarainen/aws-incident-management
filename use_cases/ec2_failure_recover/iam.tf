resource "aws_iam_role" "lambda_exec_role" {
  name = "recover-ec2-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "recover-ec2-lambda-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeInstances", "ec2:StartInstances", "ec2:RunInstances", "ec2:CreateTags"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem"],
        Resource = "arn:aws:dynamodb:eu-central-1:${data.aws_caller_identity.current.account_id}:table/incident-audit-log"
      },
      {
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = var.sns_topic_arn
      }
    ]
  })
}
