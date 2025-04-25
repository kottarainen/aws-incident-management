import boto3
import os

cloudwatch = boto3.client('cloudwatch')
stepfunctions = boto3.client('stepfunctions')

def lambda_handler(event, context):
    alarm_name = os.environ['ALARM_NAME']
    state_machine_arn = os.environ['SFN_ARN']
    
    try:
        response = cloudwatch.describe_alarms(
            AlarmNames=[alarm_name]
        )
        state = response['MetricAlarms'][0]['StateValue']
        print(f"Alarm state is: {state}")
        
        if state == 'ALARM':
            stepfunctions.start_execution(
                stateMachineArn=state_machine_arn
            )
            print("Step function triggered.")
            return {"status": "Step function triggered."}
        else:
            return {"status": "Alarm not in ALARM state."}
    except Exception as e:
        print(f"Error: {str(e)}")
        return {"error": str(e)}
