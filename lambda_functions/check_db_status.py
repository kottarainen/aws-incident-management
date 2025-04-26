import boto3
import os

rds = boto3.client('rds')

def lambda_handler(event, context):
    db_instance_id = os.environ['DB_INSTANCE_ID']

    try:
        response = rds.describe_db_instances(DBInstanceIdentifier=db_instance_id)
        status = response['DBInstances'][0]['DBInstanceStatus']
        print(f"Current DB status: {status}")

        # Handle different statuses
        if status == "available":
            return {"status": "available"}
        elif status == "stopped":
            return {"status": "stopped"}
        elif status == "starting":
            return {"status": "starting"}
        elif status == "stopping":
            return {"status": "stopping"}
        else:
            return {"status": "unknown"}

    except Exception as e:
        print(f"Error checking RDS status: {str(e)}")
        raise e
