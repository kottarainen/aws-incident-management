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
        is_already_remediated = False
        try:
            tags = s3.get_bucket_tagging(Bucket=bucket_name)['TagSet']
            is_already_remediated = any(
                tag['Key'] == 'AutoRemediated' and tag['Value'] == 'true'
                for tag in tags
            )

            if is_already_remediated:
                acl_response = s3.get_bucket_acl(Bucket=bucket_name)
                grants_current = acl_response.get('Grants', [])

                still_public = any(
                    isinstance(grant, dict) and
                    grant.get('Grantee', {}).get('URI') == "http://acs.amazonaws.com/groups/global/AllUsers"
                    for grant in grants_current
                )

                if not still_public:
                    print("Bucket is private and already auto-remediated. Skipping.")
                    return {
                        'statusCode': 200,
                        'body': "Already remediated and no public access present."
                    }

        except s3.exceptions.ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchTagSet':
                raise

        # Check if public access was granted in the triggering event
        grants = event['detail']['requestParameters'] \
            .get('AccessControlPolicy', {}) \
            .get('AccessControlList', {}) \
            .get('Grant', [])

        if not isinstance(grants, list):
            print("Unexpected format: 'Grant' is not a list.")
            return {
                'statusCode': 200,
                'body': "Grants format not as expected. Skipping."
            }

        for grant in grants:
            if not isinstance(grant, dict):
                continue

            grantee = grant.get('Grantee', {})
            if isinstance(grantee, dict) and grantee.get('URI') == "http://acs.amazonaws.com/groups/global/AllUsers":
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
