import boto3
import os
import uuid
from datetime import datetime

lambda_client = boto3.client('lambda')
sns_client = boto3.client('sns')
dynamodb = boto3.resource('dynamodb')

AUDIT_LOG_TABLE = os.environ.get("AUDIT_LOG_TABLE")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")

table = dynamodb.Table(AUDIT_LOG_TABLE)

def log_audit_event(resource, status, error=None):
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'LambdaMemoryExhaustion',
            'resourceId': resource,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': 'Increased Lambda memory allocation',
            'status': status,
            'details': {
                'region': os.environ.get("AWS_REGION", "unknown")
            },
            'errorMessage': error or ""
        })
        print("Audit event logged.")
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")

def lambda_handler(event, context):
    print("Received event:", event)

    try:
        # Extract the affected Lambda function name from alarm description or tag manually
        function_name = "MemoryTestLambda" 

        # Get current function config
        response = lambda_client.get_function_configuration(FunctionName=function_name)
        current_memory = response['MemorySize']
        print(f"Current memory: {current_memory} MB")

        # Increase memory by a safe increment
        new_memory = current_memory + 64
        print(f"Updating memory to {new_memory} MB")

        lambda_client.update_function_configuration(
            FunctionName=function_name,
            MemorySize=new_memory
        )

        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="Lambda Memory Increased",
            Message=f"Lambda function '{function_name}' experienced memory exhaustion. Memory size increased to {new_memory} MB."
        )

        log_audit_event(function_name, "Success")

        return {
            'statusCode': 200,
            'body': f"Memory updated to {new_memory} MB for {function_name}"
        }

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        log_audit_event("MemoryTestLambda", "Failure", str(e))
        return {
            'statusCode': 500,
            'body': str(e)
        }
