#!/usr/bin/env python3

import os

import boto3


def lambda_handler(event, context):

    ec2 = boto3.client("ec2")

    filters = [
        {'Name': 'instance-state-name', 'Values': ['running']},
        {'Name': f'tag:Name', 'Values': [os.environ.get("TAG_VALUE")]}
    ]

    response = ec2.describe_instances(Filters=filters)

    ips = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            ips.append(instance.get('PrivateIpAddress'))

    if ips:
        route53 = boto3.client('route53')
        response = route53.change_resource_record_sets(
            HostedZoneId=os.environ.get("HOSTED_ZONE_ID"),
            ChangeBatch={
                'Comment': 'Continuous monitoring',
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': os.environ.get("DNS_NAME"),
                            'Type': 'A',
                            'TTL': 60,
                            'ResourceRecords': [{'Value': ip} for ip in ips]
                        }
                    }
                ]
            }
        )

if __name__ == "__main__":
    lambda_handler("", "")
