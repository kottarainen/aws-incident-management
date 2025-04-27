import json
import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
table = dynamodb.Table(os.environ['AUDIT_LOG_TABLE'])

def log_audit_event(instance_id, status, error=None):
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'HighNetworkInTraffic',
            'resourceId': instance_id,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': 'Detected abnormal network traffic',
            'status': status,
            'details': {
                'region': os.environ.get('AWS_REGION', 'eu-central-1')
            },
            'errorMessage': error or "None"
        })
        print("Audit event logged.")
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")

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
