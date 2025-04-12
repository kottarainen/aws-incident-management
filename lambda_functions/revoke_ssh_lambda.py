import json
import boto3
import os

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        detail = event['detail']
        sg_id = detail['requestParameters']['groupId']
        ip_permissions = detail['requestParameters']['ipPermissions']['items']

        revoked = False

        for perm in ip_permissions:
            protocol = perm.get('ipProtocol')
            from_port = perm.get('fromPort')
            ip_ranges = perm.get('ipRanges', {}).get('items', [])

            for ip_range in ip_ranges:
                cidr = ip_range.get('cidrIp')
                if protocol == "tcp" and from_port == 22 and cidr == "0.0.0.0/0":
                    print(f"Revoking SSH access from 0.0.0.0/0 on SG {sg_id}")

                    # Revoke the exact permission
                    ec2.revoke_security_group_ingress(
                        GroupId=sg_id,
                        IpPermissions=[
                            {
                                'IpProtocol': protocol,
                                'FromPort': from_port,
                                'ToPort': from_port,
                                'IpRanges': [{'CidrIp': cidr}]
                            }
                        ]
                    )
                    revoked = True

        if revoked:
            # Tag the SG to show it's been auto-remediated
            ec2.create_tags(
                Resources=[sg_id],
                Tags=[{'Key': 'AutoRemediated', 'Value': 'true'}]
            )

            # SNS alert
            sns.publish(
                TopicArn=os.environ['SNS_TOPIC_ARN'],
                Subject="Unauthorized SSH Access Revoked",
                Message=f"Security Group {sg_id} had public SSH access. Rule was revoked automatically by Lambda."
            )
            print("Remediation complete and notification sent.")
        else:
            print("No public SSH access found in this event.")

        return {
            'statusCode': 200,
            'body': json.dumps('Lambda execution complete.')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error occurred: {str(e)}")
        }
