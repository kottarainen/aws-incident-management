import json
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    try:
        bucket_name = event['detail']['requestParameters']['bucketName']
        print(f"Checking bucket: {bucket_name}")

        # Set ACL to private
        s3.put_bucket_acl(
            Bucket=bucket_name,
            ACL='private'
        )

        print(f"Bucket {bucket_name} ACL changed to private.")
        return {
            'statusCode': 200,
            'body': f"Bucket {bucket_name} access changed to private."
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Failed to change bucket ACL: {str(e)}"
        }
