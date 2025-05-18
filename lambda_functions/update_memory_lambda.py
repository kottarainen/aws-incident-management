import boto3
import os
import json

def lambda_handler(event, context):
    lambda_client = boto3.client('lambda')

    function_name = event.get("functionName")
    current_memory = event.get("currentMemory")
    max_memory = 2048

    if not function_name or current_memory is None:
        return {"error": "Missing functionName or currentMemory in input"}

    new_memory = min(current_memory * 2, max_memory)

    if current_memory >= max_memory:
        return {
            "functionName": function_name,
            "memoryUpdated": False,
            "message": "Already at max memory",
            "newMemory": current_memory
        }

    try:
        lambda_client.update_function_configuration(
            FunctionName=function_name,
            MemorySize=new_memory
        )
        return {
            "functionName": function_name,
            "memoryUpdated": True,
            "newMemory": new_memory
        }
    except Exception as e:
        return {"error": str(e)}