#!/usr/bin/env python3

from pathlib import Path
import json
import sys

import boto3

"""
"event":
    {
        "Records": [
            "Sns":
                "Message": ""
        ]
    }
"""


def lambda_handler(event, context):

    message = json.loads(event["Records"][0]["Sns"]["Message"])
    print(json.dumps(message, indent=2))

    ssm = boto3.client("ssm")

    if "EC2InstanceId" in message:
        commands_file = (
            f"lambda_scaledown_{message['AutoScalingGroupName'].split('-')[-1]}.sh"
        )
        ssm.send_command(
            InstanceIds=[message["EC2InstanceId"]],
            DocumentName="AWS-RunShellScript",
            Parameters={
                "commands": [Path(commands_file).read_text()],
            },
            TimeoutSeconds=60,
        )


if __name__ == "__main__":
    lambda_handler(json.loads(sys.argv[1]), "")
