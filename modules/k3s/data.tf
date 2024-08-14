data "aws_iam_policy_document" "this" {
  version = "2012-10-17"
  statement {
    sid = "log"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.this.arn}:log-stream:*"]
  }
  statement {
    sid = "s3"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "this-assume" {
  statement {
    sid = "lambda"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this-s3" {

  statement {
    sid = "full"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.this-files.arn,
        var.aws.session_context.issuer_arn,
      ]
    }
  }

  # statement {
  #   sid    = "ec2"
  #   effect = "Allow"
  #   actions = [
  #     "s3:GetObject",
  #     "s3:GetObjectVersion"
  #   ]
  #   resources = [
  #     aws_s3_bucket.this.arn,
  #     "${aws_s3_bucket.this.arn}/*",
  #   ]
  #   principals {
  #     type = "AWS"
  #     identifiers = [
  #       aws_iam_role.this-controlplane.arn,
  #       aws_iam_role.this-worker.arn,
  #     ]
  #   }
  # }

}