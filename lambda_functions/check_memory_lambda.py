import boto3
import os
import json

def lambda_handler(event, context):
    lambda_client = boto3.client('lambda')
    target_lambda = os.environ.get("TARGET_LAMBDA")

    if not target_lambda:
        return {"error": "TARGET_LAMBDA environment variable not set."}

    try:
        config = lambda_client.get_function_configuration(FunctionName=target_lambda)
        return {
            "functionName": target_lambda,
            "currentMemory": config['MemorySize']
        }
    except Exception as e:
        return {"error": str(e)}