import json
import sys
from urllib.request import urlopen

import boto3
import urllib3

"""
"event":
    {
        "bucket": "my-bucket",
        "prefix": "path/foo.tar.gz",
        "url": "https://get.helm.sh/foo.tar.gz"
    }
"""


def lambda_handler(event, context):

    print(event)
    s3 = boto3.resource("s3")
    http = urllib3.PoolManager()

    # check for object, then download
    s3_object = list(s3.Bucket(event["bucket"]).objects.filter(Prefix=event["prefix"]))
    if len(s3_object) > 0 and s3_object[0].key == event["prefix"]:
        print(f'INFO {event["prefix"]} skipping')
    else:
        print(f'INFO {event["prefix"]} downloading')
        with urlopen(event["url"]):
            s3.meta.client.upload_fileobj(
                http.request("GET", event["url"], preload_content=False),
                event["bucket"],
                event["prefix"],
            )
        print(f'INFO {event["prefix"]} complete')

    return {"statusCode": 200, "body": json.dumps("finished")}


if __name__ == "__main__":
    lambda_handler(json.loads(sys.argv[1]), "")
