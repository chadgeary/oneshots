#!/usr/bin/env python3

import os

import boto3


def lambda_handler(event, context):

    ec2 = boto3.client("ec2")

    filters = [
        {"Name": "instance-state-name", "Values": ["running"]},
        {"Name": f"tag:Name", "Values": [f'{os.environ.get("TAG_VALUE")}-controlplane']},
    ]

    response = ec2.describe_instances(Filters=filters)

    ips = []
    for reservation in response["Reservations"]:
        for instance in reservation["Instances"]:
            ips.append(instance.get("PrivateIpAddress"))

    route53 = boto3.client("route53")
    if ips:
        print(f'INFO instances/ips: {ips}')
        response = route53.change_resource_record_sets(
            HostedZoneId=os.environ.get("HOSTED_ZONE_ID"),
            ChangeBatch={
                "Comment": "Continuous monitoring",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": f'controlplane.{os.environ.get("TAG_VALUE")}.internal',
                            "Type": "A",
                            "TTL": 60,
                            "ResourceRecords": [{"Value": ip} for ip in ips],
                        },
                    }
                ],
            },
        )
    else:
        print(f'WARN no instances/ips')
        response = route53.change_resource_record_sets(
            HostedZoneId=os.environ.get("HOSTED_ZONE_ID"),
            ChangeBatch={
                "Comment": "Continuous monitoring",
                "Changes": [
                    {
                        "Action": "UPSERT",
                        "ResourceRecordSet": {
                            "Name": f'controlplane.{os.environ.get("TAG_VALUE")}.internal',
                            "Type": "A",
                            "TTL": 60,
                            "ResourceRecords": [{"Value": "127.0.0.1"}],
                        },
                    }
                ],
            },
        )


if __name__ == "__main__":
    lambda_handler("", "")
