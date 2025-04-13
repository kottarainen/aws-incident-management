output "incident_alerts_topic_arn" {
  value = aws_sns_topic.incident_alerts.arn
}

output "monitored_bucket_name" {
  value = aws_s3_bucket.monitored_bucket.id
}