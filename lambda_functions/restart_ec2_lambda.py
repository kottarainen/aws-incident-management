import boto3
import json

ec2 = boto3.client("ec2")

def lambda_handler(event, context):
    print("Event received:", json.dumps(event))

    instance_id = event["detail"]["instance-id"]
    print(f"Restarting EC2 instance: {instance_id}")

    try:
        ec2.stop_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} stopped successfully.")

        ec2.start_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} started successfully.")

        return {
            "statusCode": 200,
            "body": json.dumps(f"Instance {instance_id} restarted successfully.")
        }

    except Exception as e:
        print(f"Error restarting instance: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error restarting instance: {str(e)}")
        }
