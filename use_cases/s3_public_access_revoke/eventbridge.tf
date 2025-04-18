resource "aws_cloudwatch_event_rule" "s3_public_acl_change" {
  name        = "DetectS3PublicAccess"
  description = "Detects changes that make S3 buckets public"
  event_bus_name = "default"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : ["PutBucketAcl"]
    }
  })
  
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.s3_public_acl_change.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.revoke_s3_public_access.arn
}
