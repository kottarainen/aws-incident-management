import json
import boto3
import os
import uuid
from datetime import datetime

s3 = boto3.client('s3')
sns = boto3.client('sns')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['AUDIT_LOG_TABLE'])

def log_audit_event(bucket_name, status, error=None):
    try:
        table.put_item(Item={
            'incidentId': str(uuid.uuid4()),
            'useCase': 'S3PublicAccess',
            'resourceId': bucket_name,
            'timestamp': datetime.utcnow().isoformat(),
            'actionTaken': 'Revoke public S3 ACL',
            'status': status,
            'details': {
                'region': os.environ.get("AWS_REGION", "unknown")
            },
            'errorMessage': error or ""
        })
        print("Audit event logged.")
    except Exception as e:
        print(f"Failed to log audit event: {str(e)}")

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        bucket_name = event['detail']['requestParameters']['bucketName']
        print(f"Checking bucket: {bucket_name}")

        # Check if already remediated
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
                    log_audit_event(bucket_name, "Skipped - already remediated")
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
            log_audit_event(bucket_name, "Skipped - unexpected grant format")
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

                # Notify via SNS
                sns.publish(
                    TopicArn=os.environ['SNS_TOPIC_ARN'],
                    Subject="S3 Public Access Revoked",
                    Message=f"S3 bucket {bucket_name} was made public and access was automatically revoked."
                )

                log_audit_event(bucket_name, "Success")
                print("SNS notification sent.")
                return {
                    'statusCode': 200,
                    'body': f"Bucket {bucket_name} access changed to private and notification sent."
                }

        print("No public access found. Nothing to do.")
        log_audit_event(bucket_name, "Skipped - no public access found")
        return {
            'statusCode': 200,
            'body': "No public grants found."
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        log_audit_event(bucket_name if 'bucket_name' in locals() else "unknown", "Failure", str(e))
        return {
            'statusCode': 500,
            'body': f"Error occurred: {str(e)}"
        }
