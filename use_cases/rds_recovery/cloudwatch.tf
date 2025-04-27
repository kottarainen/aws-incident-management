resource "aws_cloudwatch_metric_alarm" "rds_connection_alarm" {
  alarm_name          = "RDSLowConnectionsAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Triggered when there are 0 DB connections"
  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }
  treat_missing_data = "breaching"
  actions_enabled     = true
}

resource "aws_cloudwatch_event_rule" "rds_alarm_trigger" {
  name        = "TriggerRDSRecoveryStepFunction"
  description = "Triggers Step Function when RDS connection alarm goes into ALARM state"
  event_pattern = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    "detail": {
      "alarmName": ["RDSLowConnectionsAlarm"],
      "state": {
        "value": ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "step_function_target" {
  rule      = aws_cloudwatch_event_rule.rds_alarm_trigger.name
  arn       = aws_sfn_state_machine.rds_recovery_sfn.arn
  role_arn  = aws_iam_role.eventbridge_invoke_stepfn_role.arn
}

resource "aws_iam_role" "eventbridge_invoke_stepfn_role" {
  name = "eventbridge-stepfn-trigger-role"

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

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "AllowStepFunctionInvoke"
  role = aws_iam_role.eventbridge_invoke_stepfn_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: ["states:StartExecution"],
        Resource: aws_sfn_state_machine.rds_recovery_sfn.arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "poll_every_3_min" {
  name                = "PollRDSAlarmEvery3Min"
  schedule_expression = "rate(3 minutes)"
}

resource "aws_cloudwatch_event_target" "trigger_poll_lambda" {
  rule = aws_cloudwatch_event_rule.poll_every_3_min.name
  arn  = aws_lambda_function.poll_rds_alarm_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge_schedule" {
  statement_id  = "AllowExecutionFromScheduledEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.poll_rds_alarm_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.poll_every_3_min.arn
}
