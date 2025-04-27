resource "aws_sfn_state_machine" "rds_recovery_sfn" {
  name     = "RDSRecoveryWorkflow"
  role_arn = aws_iam_role.rds_recovery_lambda_exec.arn

  definition = jsonencode({
    StartAt = "Check RDS",
    States = {
      "Check RDS" = {
        Type = "Task",
        Resource = aws_lambda_function.check_db_status.arn,
        Next = "Evaluate Status"
      },
      "Evaluate Status" = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.status",
            StringEquals = "available",
            Next = "Success"
          },
                    {
            Variable = "$.status",
            StringEquals = "starting",
            Next = "Wait 2 Minutes"
          },
                    {
            Variable = "$.status",
            StringEquals = "stopping",
            Next = "Wait 2 Minutes"
          },
                    {
            Variable = "$.status",
            StringEquals = "stopped",
            Next = "Start RDS"
          }
        ],
        Default = "Alert Failure"
      },
      "Start RDS" = {
        Type = "Task",
        Resource = aws_lambda_function.start_rds_instance.arn,
        Next = "Wait 2 Minutes"
      },
      "Wait 2 Minutes" = {
        Type = "Wait",
        Seconds = 120,
        Next = "Recheck RDS"
      },
      "Recheck RDS" = {
        Type = "Task",
        Resource = aws_lambda_function.check_db_status.arn,
        Next = "Evaluate Status"
      },
      "Alert Failure" = {
        Type = "Task",
        Resource = aws_lambda_function.alert_failure.arn,
        End = true
      },
      "Success" = {
        Type = "Pass",
        End = true
      }
    }
  })
}
