import json
import boto3
import os
import uuid
from datetime import datetime

s3 = boto3.client('s3')
sns = boto3.client('sns')
dynamodb = boto3.resource("dynamodb")
table_name = os.environ.get("AUDIT_LOG_TABLE", "NOT_SET")
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    print(f"Audit log table name from env: {table_name}")
    
    # TRY TO WRITE TO DYNAMODB
    try:
        response = table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'TestWrite',
            'timestamp': datetime.utcnow().isoformat(),
            'status': 'TestSuccess'
        })
        print("DynamoDB write test succeeded.")
    except Exception as e:
        print(f"DynamoDB write failed: {str(e)}")
    
    return {
        'statusCode': 200,
        'body': "DynamoDB test write attempted."
    }
