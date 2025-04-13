import json
import boto3
import os
import uuid
from datetime import datetime

ec2 = boto3.client("ec2")
sns = boto3.client("sns")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["AUDIT_LOG_TABLE"])

def log_audit_event(original_instance_id, new_instance_id, status, error=None):
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'EC2FailureRecovery',
            'resourceId': original_instance_id,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': 'Launched new EC2 instance from original AMI',
            'status': status,
            'newResourceId': new_instance_id,
            'errorMessage': error or ""
        })
        print("Audit event logged.")
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        instance_id = event["detail"]["instance-id"]
        print(f"Instance {instance_id} is unhealthy. Launching replacement.")

        # Get AMI and other launch details of the original instance
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response["Reservations"][0]["Instances"][0]
        ami_id = instance["ImageId"]
        instance_type = instance["InstanceType"]
        key_name = instance.get("KeyName")
        subnet_id = instance["SubnetId"]
        security_groups = [sg["GroupId"] for sg in instance["SecurityGroups"]]

        # Launch a new instance with the same configuration
        new_instance = ec2.run_instances(
            ImageId=ami_id,
            InstanceType=instance_type,
            KeyName=key_name,
            SubnetId=subnet_id,
            SecurityGroupIds=security_groups,
            MinCount=1,
            MaxCount=1,
            TagSpecifications=[{
                'ResourceType': 'instance',
                'Tags': [{'Key': 'Name', 'Value': 'RecoveredInstance'}]
            }]
        )

        new_instance_id = new_instance["Instances"][0]["InstanceId"]
        print(f"Launched new instance: {new_instance_id}")

        # SNS Notification
        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="EC2 Instance Recovery",
            Message=f"EC2 instance {instance_id} was stopped or unhealthy. New instance {new_instance_id} has been launched."
        )

        log_audit_event(instance_id, new_instance_id, "Success")

        return {
            "statusCode": 200,
            "body": f"New instance {new_instance_id} launched to replace {instance_id}"
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        log_audit_event(instance_id if 'instance_id' in locals() else "unknown", "none", "Failure", str(e))
        return {
            "statusCode": 500,
            "body": f"Error occurred: {str(e)}"
        }
