resource "aws_sfn_state_machine" "rds_recovery_sfn" {
  name     = "RDSRecoveryWorkflow"
  role_arn = aws_iam_role.rds_recovery_lambda_exec.arn

  definition = jsonencode({
    StartAt = "Check RDS",
    States = {
      "Check RDS" = {
        Type = "Task",
        Resource = aws_lambda_function.check_db_status.arn,
        Next = "Is RDS Available?"
      },
      "Is RDS Available?" = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.status",
            StringEquals = "available",
            Next = "Success"
          }
        ],
        Default = "Start RDS"
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
        Next = "Is RDS Available After Restart?"
      },
      "Is RDS Available After Restart?" = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.status",
            StringEquals = "available",
            Next = "Success"
          }
        ],
        Default = "Alert Failure"
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
