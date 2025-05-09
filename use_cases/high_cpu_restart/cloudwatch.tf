resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when CPU usage exceeds 80% for 2 minutes"
  dimensions = {
    InstanceId = "i-09e61f90290c57ed0"
  }
  actions_enabled = true
  #alarm_actions   = [aws_sns_topic.incident_alerts.arn]
  alarm_actions = [var.sns_topic_arn]
}
