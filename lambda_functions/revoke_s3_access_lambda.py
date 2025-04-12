import json
import boto3
import os

s3 = boto3.client('s3')
sns = boto3.client('sns')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        bucket_name = event['detail']['requestParameters']['bucketName']
        print(f"Checking bucket: {bucket_name}")

        # Check if this bucket was already remediated
        try:
            tags = s3.get_bucket_tagging(Bucket=bucket_name)['TagSet']
            for tag in tags:
                if tag['Key'] == 'AutoRemediated' and tag['Value'] == 'true':
                    print("Bucket already auto-remediated. Skipping.")
                    return {
                        'statusCode': 200,
                        'body': "Already remediated."
                    }
        except s3.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchTagSet':
                raise

        # Check if public access is granted
        grants = event['detail']['requestParameters'].get('AccessControlPolicy', {}).get('Grant', [])
        for grant in grants:
            grantee = grant.get('Grantee', {})
            if grantee.get('URI') == "http://acs.amazonaws.com/groups/global/AllUsers":
                print("Public access detected. Revoking...")

                # Revoke ACL
                s3.put_bucket_acl(Bucket=bucket_name, ACL='private')

                # Tag the bucket
                s3.put_bucket_tagging(
                    Bucket=bucket_name,
                    Tagging={
                        'TagSet': [
                            {'Key': 'AutoRemediated', 'Value': 'true'}
                        ]
                    }
                )

                # Publish SNS notification
                sns.publish(
                    TopicArn=os.environ['SNS_TOPIC_ARN'],
                    Subject="S3 Public Access Revoked",
                    Message=f"S3 bucket {bucket_name} was made public and access was automatically revoked."
                )

                print("SNS notification sent.")
                return {
                    'statusCode': 200,
                    'body': f"Bucket {bucket_name} access changed to private and notification sent."
                }

        print("No public access found. Nothing to do.")
        return {
            'statusCode': 200,
            'body': "No public grants found."
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error occurred: {str(e)}"
        }
