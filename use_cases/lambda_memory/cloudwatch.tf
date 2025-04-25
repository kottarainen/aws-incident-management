resource "aws_cloudwatch_event_rule" "lambda_error_rule" {
  name        = "DetectLambdaError"
  description = "Triggers when MemoryTestLambda logs an error"
  event_pattern = jsonencode({
    source = ["aws.logs"]
  })
}

resource "aws_cloudwatch_event_target" "target_increase_memory_lambda" {
  rule      = aws_cloudwatch_event_rule.lambda_error_rule.name
  target_id = "InvokeRemediation"
  arn       = aws_lambda_function.increase_memory_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.increase_memory_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_error_rule.arn
}
