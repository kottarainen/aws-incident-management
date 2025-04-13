import boto3
import time
import uuid
import os
from datetime import datetime

ec2_client = boto3.client("ec2", region_name="eu-central-1")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["AUDIT_LOG_TABLE"])

def log_audit_event(instance_id, status, error=None):
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'HighCPU',
            'resourceId': instance_id,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': 'Restart EC2',
            'status': status,
            'details': {
                'region': 'eu-central-1'
            },
            'errorMessage': error or ""
        })
        print("Audit event logged.")
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")

def lambda_handler(event, context):
    instance_id = event["detail"]["instance-id"]
    print(f"Event received: {event}")
    print(f"Restarting EC2 instance: {instance_id}")

    try:
        # stop the instance
        ec2_client.stop_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} stopping...")

        # wait for the instance to fully stop
        while True:
            instance_status = ec2_client.describe_instances(InstanceIds=[instance_id])
            state = instance_status["Reservations"][0]["Instances"][0]["State"]["Name"]
            print(f"Current state: {state}")

            if state == "stopped":
                print(f"Instance {instance_id} has stopped.")
                break
            time.sleep(5)

        # start the instance
        ec2_client.start_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} started successfully.")

        log_audit_event(instance_id, "Success")

        return {
            "statusCode": 200,
            "body": f"Instance {instance_id} restarted successfully."
        }

    except Exception as e:
        print(f"Error restarting instance: {str(e)}")
        log_audit_event(instance_id, "Failure", str(e))

        return {
            "statusCode": 500,
            "body": f"Error restarting instance: {str(e)}"
        }
