resource "aws_cloudwatch_metric_alarm" "high_network_in_alarm" {
  alarm_name          = "HighNetworkInTraffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 10000
  alarm_description   = "Triggers when NetworkIn exceeds 10,000 bytes over 2 minutes"
  dimensions = {
    InstanceId = var.instance_id
  }
  treat_missing_data = "notBreaching"
  actions_enabled     = true
}

resource "aws_cloudwatch_event_rule" "high_network_alarm_trigger" {
  name        = "TriggerHighNetworkAlarmLambda"
  description = "Triggers Lambda when High NetworkIn alarm goes into ALARM"
  event_pattern = jsonencode({
    source = ["aws.cloudwatch"],
    "detail-type" = ["CloudWatch Alarm State Change"],
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.high_network_in_alarm.alarm_name],
      state = {
        value = ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "high_network_alarm_target" {
  rule      = aws_cloudwatch_event_rule.high_network_alarm_trigger.name
  arn       = aws_lambda_function.network_alarm_handler.arn
  role_arn  = aws_iam_role.eventbridge_invoke_network_lambda_role.arn
}
resource "aws_cloudwatch_metric_alarm" "low_network_out_alarm" {
  alarm_name          = "LowNetworkOutTraffic"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 10000
  alarm_description   = "Triggers when NetworkOut is below 10,000 bytes"
  dimensions = {
    InstanceId = var.instance_id
  }
  treat_missing_data = "notBreaching"
  actions_enabled     = true
}

resource "aws_cloudwatch_event_rule" "low_network_alarm_trigger" {
  name        = "TriggerLowNetworkAlarmLambda"
  description = "Triggers Lambda when Low NetworkOut alarm goes into ALARM"
  event_pattern = jsonencode({
    source = ["aws.cloudwatch"],
    "detail-type" = ["CloudWatch Alarm State Change"],
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.low_network_out_alarm.alarm_name],
      state = {
        value = ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "low_network_alarm_target" {
  rule      = aws_cloudwatch_event_rule.low_network_alarm_trigger.name
  arn       = aws_lambda_function.network_alarm_handler.arn
  role_arn  = aws_iam_role.eventbridge_invoke_network_lambda_role.arn
}

# shared IAM role and policy
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
    Statement: [{
      Effect = "Allow",
      Action = ["lambda:InvokeFunction"],
      Resource = aws_lambda_function.network_alarm_handler.arn
    }]
  })
}
