#!/usr/bin/env python3

import json
import os
import sys
from pathlib import Path

import boto3

""" lifecyclehook
{ "Records": [ { "Sns": { "Message": "{ \"EC2InstanceId\": \"i-00000000000000000\"}" }}]}
"""

""" spotinterruption
{ "detail-type": "", "detail": { "instance-id": "i-00000000000000000" }}
"""


def lambda_handler(event, context):

    print(json.dumps(event))

    if "Records" in event:
        event_type = "lifecyclehook"
        message = json.loads(event["Records"][0]["Sns"]["Message"])
        instance = message["EC2InstanceId"]
    elif "detail-type" in event:
        event_type = "spotinterruption"
        instance = event["detail"]["instance-id"]

    ssm = boto3.client("ssm")

    # drain / delete node
    name = os.environ["AWS_LAMBDA_FUNCTION_NAME"].replace("-gracefulshutdown", "")
    ssm.send_command(
        Targets=[
            {
                "Key": "tag:Name",
                "Values": [
                    f"{name}-controlplane",
                ],
            },
        ],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [
                f"""\
#!/usr/bin/env bash
WORKER_ID="{instance}"
export WORKER_ID
{Path("drainworker.sh").read_text()}
"""
            ],
        },
        TimeoutSeconds=60,
    )

    # graceful shutdown
    ssm.send_command(
        InstanceIds=[instance],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [
                f"""\
#!/usr/bin/env bash
EVENT_TYPE="{event_type}"
export EVENT_TYPE
{Path("gracefulshutdown.sh").read_text()}
"""
            ],
        },
        TimeoutSeconds=60,
    )


if __name__ == "__main__":
    lambda_handler(json.loads(sys.argv[1]), "")
