import json
import os
import time

from botocore.errorfactory import ClientError
import boto3
import botocore
import boto3.exceptions
import botocore.exceptions


def lambda_handler(event, context):

    name = os.environ["AWS_LAMBDA_FUNCTION_NAME"].replace("-watch", "")
    s3 = boto3.client("s3")

    objects = [
        "oidc/.well-known/openid-configuration",
        "oidc/openid/v1/jwks",
        "oidc/ca.thumbprint",
        "config"
    ]

    while True:
        try:
            for object in objects:
                s3.head_object(
                    Bucket=f"{name}-cluster",
                    Key=f"controlplane/{object}",
                )
        except s3.exceptions.ClientError as e:
            print(f"INFO waiting on controlplane/{object}")
            print(e)
            time.sleep(1)
            continue
        else:
            break
