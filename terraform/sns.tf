resource "aws_sns_topic" "incident_alerts" {
  name = "incident-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.incident_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email
}
