import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

def log_audit_event(function_name, status, error_message=None):
    table = dynamodb.Table(os.environ['AUDIT_LOG_TABLE'])
    timestamp = datetime.utcnow().isoformat()
    item = {
        'incidentId': f"{function_name}-{timestamp}",
        'timestamp': timestamp,
        'functionName': function_name,
        'status': status,
        'errorMessage': error_message or "None"
    }
    table.put_item(Item=item)

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="Network In Traffic Alert",
            Message="High incoming network traffic detected on monitored instance!"
        )
        log_audit_event("network_alarm_handler", "Success")
        return {
            'statusCode': 200,
            'body': "Alert published successfully."
        }

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        log_audit_event("network_alarm_handler", "Failure", str(e))
        return {
            'statusCode': 500,
            'body': str(e)
        }
