resource "aws_sns_topic" "incident_alerts" {
  name = "incident-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.incident_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.incident_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.restart_ec2.arn
}