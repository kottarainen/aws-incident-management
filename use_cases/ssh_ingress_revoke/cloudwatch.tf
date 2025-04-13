resource "aws_cloudwatch_event_rule" "public_ssh_detect" {
  name        = "DetectPublicSSHIngress"
  description = "Detects SSH (port 22) open to 0.0.0.0/0"
  event_pattern = jsonencode({
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventName": ["AuthorizeSecurityGroupIngress"],
      "requestParameters": {
        "ipPermissions": {
          "items": {
            "ipProtocol": ["tcp"],
            "fromPort": [22],
            "ipRanges": {
              "items": {
                "cidrIp": ["0.0.0.0/0"]
              }
            }
          }
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.public_ssh_detect.name
  target_id = "InvokeLambda"
  arn       = aws_lambda_function.revoke_ssh_access.arn
}