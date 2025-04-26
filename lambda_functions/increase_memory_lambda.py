# --- Updated increase_memory_lambda.py ---

import boto3
import os
import json
import time
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
cloudwatchlogs = boto3.client('logs')
lambda_client = boto3.client('lambda')
sns = boto3.client('sns')

MAX_MEMORY_MB = 2048  # Maximum memory limit

def log_audit_event(resource_id, status, error=None):
    table_name = os.environ.get("AUDIT_LOG_TABLE")
    if not table_name:
        print("No AUDIT_LOG_TABLE environment variable found.")
        return
    table = dynamodb.Table(table_name)
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'LambdaMemoryExhaustion',
            'resourceId': resource_id,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': 'Memory size adjusted',
            'status': status,
            'details': {
                'region': os.environ.get("REGION", "unknown")
            },
            'errorMessage': error or ""
        })
        print("Audit event logged.")
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    target_lambda = os.environ.get("TARGET_LAMBDA")
    if not target_lambda:
        print("No TARGET_LAMBDA environment variable found.")
        return {
            'statusCode': 400,
            'body': 'TARGET_LAMBDA environment variable not set.'
        }

    try:
        config = lambda_client.get_function_configuration(
            FunctionName=target_lambda
        )
        current_memory = config['MemorySize']
        print(f"Current memory size: {current_memory}MB")

        if current_memory >= MAX_MEMORY_MB:
            print(f"Memory size already at or above {MAX_MEMORY_MB}MB. Skipping update.")
            log_audit_event(target_lambda, "Skipped - memory limit reached")
            return {
                'statusCode': 200,
                'body': f"Memory already at {current_memory}MB. No update needed."
            }

        new_memory = min(current_memory * 2, MAX_MEMORY_MB)
        lambda_client.update_function_configuration(
            FunctionName=target_lambda,
            MemorySize=new_memory
        )
        print(f"Memory updated to {new_memory}MB.")

        log_audit_event(target_lambda, "Success")

        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="Lambda Memory Increased",
            Message=f"Lambda {target_lambda} memory increased to {new_memory}MB."
        )

        return {
            'statusCode': 200,
            'body': f"Memory increased to {new_memory}MB"
        }

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        log_audit_event(target_lambda, "Failure", str(e))
        return {
            'statusCode': 500,
            'body': str(e)
        }
