resource "aws_dynamodb_table" "incident_audit_log" {
  name           = "incident-audit-log"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "incidentId"

  attribute {
    name = "incidentId"
    type = "S"
  }

  tags = {
    Name        = "IncidentAuditLog"
    Environment = "ThesisMonitoring"
  }
}
