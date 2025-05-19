resource "aws_sfn_state_machine" "lambda_memory_sfn" {
  name     = "LambdaMemoryWorkflow"
  role_arn = aws_iam_role.stepfn_lambda_memory_exec.arn

  definition = jsonencode({
    Comment = "Increase Lambda Memory Workflow",
    StartAt = "CheckMemory",
    States = {
      "CheckMemory" = {
        Type     = "Task",
        Resource = aws_lambda_function.check_memory_lambda.arn,
        Next     = "NeedsUpdate?"
      },
      "NeedsUpdate?" = {
        Type = "Choice",
        Choices = [
          {
            Variable     = "$.currentMemory",
            NumericGreaterThanEquals = 2048,
            Next         = "AlreadyMaxedOut"
          }
        ],
        Default = "UpdateMemory"
      },
      "UpdateMemory" = {
        Type     = "Task",
        Resource = aws_lambda_function.update_memory_lambda.arn,
        Next     = "LogResult"
      },
      "AlreadyMaxedOut" = {
        Type     = "Pass",
        Result   = {
          message = "Memory already at or above max."
          status  = "Skipped"
        },
        Next     = "LogResult"
      },
      "LogResult" = {
        Type     = "Task",
        Resource = aws_lambda_function.log_result_lambda.arn,
        Next     = "NotifyAdmin"
      },
      "NotifyAdmin" = {
        Type     = "Task",
        Resource = aws_lambda_function.notify_admin_lambda.arn,
        End      = true
      }
    }
  })
}
