import boto3
import os

sns = boto3.client('sns')

def lambda_handler(event, context):
    topic_arn = os.environ['SNS_TOPIC_ARN']
    db_instance_id = os.environ['DB_INSTANCE_ID']

    message = f"RDS instance '{db_instance_id}' failed to recover after restart attempt."
    print(message)

    try:
        sns.publish(
            TopicArn=topic_arn,
            Subject="RDS Recovery Failure",
            Message=message
        )
        return {"alert_sent": True}
        
    except Exception as e:
        print(f"Failed to send SNS alert: {str(e)}")
        return {"alert_sent": False, "error": str(e)}
