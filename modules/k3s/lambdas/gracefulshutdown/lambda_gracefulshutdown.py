#!/usr/bin/env python3

import json
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

    print(json.dumps(event, indent=2))

    if "Records" in event:
        event_type = "lifecyclehook"
        message = json.loads(event["Records"][0]["Sns"]["Message"])
        instance = message["EC2InstanceId"]
    elif "detail-type" in event:
        event_type = "spotinterruption"
        instance = event["detail"]["instance-id"]

    ssm = boto3.client("ssm")
    ssm.send_command(
        InstanceIds=[instance],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [
                f"""\
#!/usr/bin/env bash
EVENT_TYPE="{event_type}"
{Path("gracefulshutdown.sh").read_text()}
"""
            ],
        },
        TimeoutSeconds=60,
    )


if __name__ == "__main__":
    lambda_handler(json.loads(sys.argv[1]), "")
