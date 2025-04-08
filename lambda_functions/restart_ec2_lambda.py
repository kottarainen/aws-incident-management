import boto3
import time

ec2_client = boto3.client("ec2", region_name="eu-central-1")

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
            time.sleep(5)  # wait 5 sec before checking again

        # start the instance
        ec2_client.start_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} started successfully.")

        return {
            "statusCode": 200,
            "body": f"Instance {instance_id} restarted successfully."
        }

    except Exception as e:
        print(f"Error restarting instance: {str(e)}")
        return {
            "statusCode": 500,
            "body": f"Error restarting instance: {str(e)}"
        }
