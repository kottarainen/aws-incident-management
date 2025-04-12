import json
import boto3

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        bucket_name = event['detail']['requestParameters']['bucketName']
        print(f"Checking bucket: {bucket_name}")

        # Check if the ACL grants public access
        grants = event['detail']['requestParameters'].get('AccessControlPolicy', {}).get('Grants', [])
        for grant in grants:
            grantee = grant.get('Grantee', {})
            if grantee.get('URI') == "http://acs.amazonaws.com/groups/global/AllUsers":
                print("Public access detected. Proceeding to revoke.")
                break
        else:
            print("No public access detected. Skipping action.")
            return {
                'statusCode': 200,
                'body': "No public ACL found, no action taken."
            }

        # Revoke public access by setting ACL to private
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
