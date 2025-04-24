def lambda_handler(event, context):
    a = ['a'] * (10**8)  # Force memory error
    return { 'statusCode': 200 }
