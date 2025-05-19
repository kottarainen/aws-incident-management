resource "aws_cloudwatch_event_rule" "lambda_error_rule" {
  name        = "DetectLambdaMemoryError"
  description = "Triggers Step Function on Lambda failure"

  event_pattern = jsonencode({
    source = ["aws.lambda"],
    detail-type = ["AWS API Call via CloudTrail"],
    detail = {
      eventSource = ["lambda.amazonaws.com"],
      eventName   = ["Invoke"],
      errorCode   = ["OutOfMemoryError"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_memory_sfn_target" {
  rule      = aws_cloudwatch_event_rule.lambda_error_rule.name
  arn       = aws_sfn_state_machine.lambda_memory_sfn.arn
  role_arn  = aws_iam_role.eventbridge_invoke_stepfn_role.arn
}

resource "aws_iam_role" "eventbridge_invoke_stepfn_role" {
  name = "eventbridge-sfn-lambda-memory-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_stepfn_policy" {
  name = "AllowStartLambdaMemoryStepFunction"
  role = aws_iam_role.eventbridge_invoke_stepfn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["states:StartExecution"],
        Resource = aws_sfn_state_machine.lambda_memory_sfn.arn
      }
    ]
  })
}
