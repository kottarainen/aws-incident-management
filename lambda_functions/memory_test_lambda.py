def lambda_handler(event, context):
    # Simulate some work to use memory (not dangerous)
    big_list = [i for i in range(1000000)]  # Just for testing
    return {
        'statusCode': 200,
        'body': f"Allocated list of size {len(big_list)}"
    }
