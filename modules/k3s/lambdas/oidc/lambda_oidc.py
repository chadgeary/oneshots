import json
import os
import time

import boto3
import boto3.exceptions


def lambda_handler(event, context):

    name = os.environ["AWS_LAMBDA_FUNCTION_NAME"].replace("-oidc", "")
    s3 = boto3.client("s3")
    iam = boto3.client("iam")

    objects = [
        ".well-known/openid-configuration",
        "openid/v1/jwks",
        "ca.thumbprint",
    ]

    while True:
        try:
            for object in objects:
                s3.put_object_tagging(
                    Bucket=f"{name}-k3sfiles",
                    Key=f"controlplane/oidc/{object}",
                    Tagging={
                        "TagSet": [
                            {
                                "Key": "public",
                                "Value": "true",
                            },
                        ]
                    },
                )
        except s3.exceptions.NoSuchKey:
            print(f"INFO waiting on {object}")
            time.sleep(1)
            continue
        except s3.exceptions.ClientError:
            print(f"INFO waiting on {object}")
            time.sleep(1)
            continue
        else:
            break

    thumbprint = (
        s3.get_object(
            Bucket=f"{name}-k3sfiles",
            Key=f"controlplane/oidc/ca.thumbprint",
        )["Body"]
        .read()
        .decode("utf-8")
        .replace("\n", "")
    )

    try:
        iam.create_open_id_connect_provider(
            Url=f'https://s3.{os.environ["AWS_REGION"]}.amazonaws.com/{name}-k3sfiles/oidc',
            ClientIDList=[name],
            ThumbprintList=[thumbprint],
            Tags=[
                {
                    "Key": "Name",
                    "Value": name,
                },
            ],
        )
    except iam.exceptions.EntityAlreadyExistsException:
        print("INFO provider exists, setting thumbprint")
        sts = boto3.client('sts')
        partition = context.invoked_function_arn.split(":")[1]
        account = context.invoked_function_arn.split(":")[4]
        iam.update_open_id_connect_provider_thumbprint(
            OpenIDConnectProviderArn=f'arn:{partition}:iam::{account}:oidc-provider/s3.{os.environ["AWS_REGION"]}.amazonaws.com/{name}-k3sfiles/oidc',
            ThumbprintList=[thumbprint],
        )

    return {"statusCode": 200, "body": json.dumps("Complete")}
