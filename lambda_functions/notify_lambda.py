import boto3
import os

def lambda_handler(event, context):
    sns = boto3.client('sns')
    topic_arn = os.environ.get("SNS_TOPIC_ARN")
    
    function_name = event.get("functionName")
    updated = event.get("memoryUpdated", False)
    new_memory = event.get("newMemory", "")
    error = event.get("error", "")

    try:
        if updated:
            message = f"Memory for Lambda {function_name} increased to {new_memory}MB."
        elif error:
            message = f"Error increasing memory for Lambda {function_name}: {error}"
        else:
            message = f"No update needed for Lambda {function_name}. Already at maximum memory."

        sns.publish(
            TopicArn=topic_arn,
            Subject="Lambda Memory Adjustment",
            Message=message
        )

        return {"notificationStatus": "Sent"}
    except Exception as e:
        return {"error": str(e)}