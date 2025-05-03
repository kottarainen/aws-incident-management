resource "aws_cloudwatch_metric_alarm" "high_network_in_alarm" {
  alarm_name          = "HighNetworkInTraffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 10000
  alarm_description   = "Triggers when NetworkIn exceeds ... over 2 minutes on EC2"
  dimensions = {
    InstanceId = var.instance_id
  }
  treat_missing_data = "notBreaching"
  actions_enabled     = true
}

resource "aws_cloudwatch_event_rule" "network_alarm_trigger" {
  name        = "TriggerNetworkAlarmLambda"
  description = "Triggers Lambda when NetworkIn alarm goes into ALARM state"
  event_pattern = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    "detail": {
      "alarmName": ["HighNetworkInTraffic"],
      "state": {
        "value": ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "network_alarm_target" {
  rule      = aws_cloudwatch_event_rule.network_alarm_trigger.name
  arn       = aws_lambda_function.network_alarm_handler.arn
  role_arn  = aws_iam_role.eventbridge_invoke_network_lambda_role.arn
}

resource "aws_iam_role" "eventbridge_invoke_network_lambda_role" {
  name = "eventbridge-network-lambda-trigger-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect = "Allow",
      Principal = {
        Service = "events.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "allow_lambda_invoke" {
  name = "AllowNetworkLambdaInvoke"
  role = aws_iam_role.eventbridge_invoke_network_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect = "Allow",
        Action = ["lambda:InvokeFunction"],
        Resource = aws_lambda_function.network_alarm_handler.arn
      }
    ]
  })
}
