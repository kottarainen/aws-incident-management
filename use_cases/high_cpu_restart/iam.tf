resource "aws_iam_role" "lambda_exec_role" {
  name = "incident_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_ec2_control" {
  name        = "LambdaEC2ControlPolicy"
  description = "Allows Lambda to restart EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_attach" {
  policy_arn = aws_iam_policy.lambda_ec2_control.arn
  role       = aws_iam_role.lambda_exec_role.name
}


resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  description = "Allows Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_sns_topic_policy" "default" {
  #arn = aws_sns_topic.incident_alerts.arn
  arn      = var.sns_topic_arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "SNS:Publish"
        #Resource  = aws_sns_topic.incident_alerts.arn
        Resource = var.sns_topic_arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_metric_alarm.high_cpu.arn
          }
        }
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restart_ec2.function_name
  principal     = "sns.amazonaws.com"
  #source_arn    = aws_sns_topic.incident_alerts.arn
  source_arn = var.sns_topic_arn
}
