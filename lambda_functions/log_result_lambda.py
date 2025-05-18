import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    table_name = os.environ.get("AUDIT_LOG_TABLE")
    table = dynamodb.Table(table_name)

    function_name = event.get("functionName", "unknown")
    status = "Success" if event.get("memoryUpdated") else "Skipped"
    error = event.get("error", "None")

    log_item = {
        'incidentId': str(uuid.uuid4()),
        'useCase': 'LambdaMemoryExhaustion',
        'resourceId': function_name,
        'timestamp': datetime.utcnow().isoformat(),
        'actionTaken': 'Memory size adjusted',
        'status': status,
        'region': os.environ.get("AWS_REGION", "unknown"),
        'errorMessage': error
    }

    try:
        table.put_item(Item=log_item)
        return {"logStatus": "Logged successfully"}
    except Exception as e:
        return {"error": str(e)}