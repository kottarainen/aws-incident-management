resource "aws_cloudwatch_event_rule" "ec2_instance_state_change" {
  name        = "DetectEC2StoppedUnexpectedly"
  description = "Triggers when an EC2 instance changes to stopped state unexpectedly"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["EC2 Instance State-change Notification"],
    "detail": {
      "state": ["stopped"]
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ec2_instance_state_change.name
  target_id = "InvokeRecoveryLambda"
  arn       = aws_lambda_function.recover_ec2_instance.arn
}