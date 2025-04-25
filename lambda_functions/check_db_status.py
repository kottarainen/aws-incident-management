import boto3
import os

rds = boto3.client('rds')

def lambda_handler(event, context):
    db_instance_id = os.environ['DB_INSTANCE_ID']

    try:
        response = rds.describe_db_instances(DBInstanceIdentifier=db_instance_id)
        status = response['DBInstances'][0]['DBInstanceStatus']
        print(f"DB instance status: {status}")
        return {"status": status}
        
    except Exception as e:
        print(f"Error checking DB status: {str(e)}")
        return {"status": "unknown", "error": str(e)}
