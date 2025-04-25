import boto3
import os

rds = boto3.client('rds')

def lambda_handler(event, context):
    db_instance_id = os.environ['DB_INSTANCE_ID']

    try:
        print(f"Attempting to start DB instance: {db_instance_id}")
        rds.start_db_instance(DBInstanceIdentifier=db_instance_id)
        return {"started": True}
        
    except Exception as e:
        print(f"Error starting DB instance: {str(e)}")
        return {"started": False, "error": str(e)}
