import json
import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
table = dynamodb.Table(os.environ['AUDIT_LOG_TABLE'])

def log_audit_event(resource_id, use_case, status, error=None):
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': use_case,
            'resourceId': resource_id,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': f'Detected anomaly: {use_case}',
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
        # Extract alarm details from CloudWatch EventBridge event
        detail = event.get('detail', {})
        alarm_name = detail.get('alarmName', 'UnknownAlarm')
        instance_id = 'UnknownInstance'

        # Try to extract InstanceId from the CloudWatch dimensions (if included)
        try:
            instance_id = detail['configuration']['metrics'][0]['metricStat']['metric']['dimensions']['InstanceId']
        except:
            print("Could not extract InstanceId, defaulting to UnknownInstance.")

        # Use a readable label for the use case based on alarm name
        if "NetworkIn" in alarm_name:
            use_case = "HighNetworkInTraffic"
            alert_message = f"High NetworkIn traffic detected on instance {instance_id}."
        elif "NetworkOut" in alarm_name:
            use_case = "LowNetworkOutTraffic"
            alert_message = f"Low NetworkOut traffic detected on instance {instance_id}."
        else:
            use_case = alarm_name
            alert_message = f"Network anomaly detected: {alarm_name}"

        # Send alert
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"Network Traffic Alert: {use_case}",
            Message=alert_message
        )

        # Log to DynamoDB
        log_audit_event(instance_id, use_case, "Success")
        return {
            'statusCode': 200,
            'body': f"Alert for {use_case} published successfully."
        }

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        log_audit_event("unknown", "NetworkAlarmHandler", "Failure", str(e))
        return {
            'statusCode': 500,
            'body': str(e)
        }
