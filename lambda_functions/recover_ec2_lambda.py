import boto3
import os
import uuid
from datetime import datetime

ec2 = boto3.client("ec2", region_name=os.environ.get("REGION", "eu-central-1"))
sns = boto3.client("sns")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["AUDIT_LOG_TABLE"])

def log_audit_event(instance_id, status, action, error=None):
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'EC2FailureRecovery',
            'resourceId': instance_id,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': action,
            'status': status,
            'errorMessage': error or ""
        })
        print("Audit event logged.")
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")

def lambda_handler(event, context):
    print("Received event:", event)

    try:
        detail = event['detail']
        instance_id = detail['instance-id']
        state = detail['state']
        print(f"Detected instance state change: {instance_id} -> {state}")

        if state not in ["stopping", "stopped", "terminated"]:
            print("No recovery needed for this state.")
            log_audit_event(instance_id, "Ignored", "State not critical")
            return {
                'statusCode': 200,
                'body': "No action taken."
            }

        # Describe the old instance to get its config
        response = ec2.describe_instances(InstanceIds=[instance_id])
        instance = response['Reservations'][0]['Instances'][0]

        ami = instance['ImageId']
        instance_type = instance['InstanceType']
        sg_ids = [sg['GroupId'] for sg in instance['SecurityGroups']]
        subnet_id = instance['SubnetId']
        key_name = instance.get('KeyName', None)
        tags = instance.get('Tags', [])

        print(f"Launching new instance to replace {instance_id}...")

        launch_args = {
            'ImageId': ami,
            'InstanceType': instance_type,
            'SecurityGroupIds': sg_ids,
            'SubnetId': subnet_id,
            'TagSpecifications': [{
                'ResourceType': 'instance',
                'Tags': tags
            }],
            'MinCount': 1,
            'MaxCount': 1
        }

        if key_name:
            launch_args['KeyName'] = key_name

        ec2.run_instances(**launch_args)

        sns.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject="EC2 Instance Recovery",
            Message=f"A new EC2 instance was launched to replace failed instance {instance_id}."
        )

        log_audit_event(instance_id, "Success", "Launched replacement EC2")
        return {
            'statusCode': 200,
            'body': f"Replacement instance launched for {instance_id}"
        }

    except Exception as e:
        print(f"Error recovering instance: {str(e)}")
        log_audit_event(instance_id if 'instance_id' in locals() else "unknown", "Failure", "Recovery failed", str(e))
        return {
            'statusCode': 500,
            'body': f"Error: {str(e)}"
        }
