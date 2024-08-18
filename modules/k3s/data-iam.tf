data "aws_iam_policy_document" "this-controlplane" {
  version = "2012-10-17"
  statement {
    sid = "asg"
    actions = [
      "autoscaling:CompleteLifecycleAction"
    ]
    effect = "Allow"
    resources = [
      "arn:${var.aws.partition.id}:autoscaling:${var.aws.region.name}:${var.aws.caller_identity.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.aws.default_tags.tags["Name"]}-controlplane"
    ]
  }
  statement {
    sid = "ecr"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "ssm"
    actions = [
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",

    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "s31"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/files/*",
    ]
    effect = "Allow"
  }
  statement {
    sid = "s32"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/controlplane/*",
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "this-controlplane-assume" {
  statement {
    sid = "ec2"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this-controlplane-scaledown" {
  version = "2012-10-17"
  statement {
    sid = "sns"
    actions = [
      "sns:Publish"
    ]
    effect    = "Allow"
    resources = [aws_sns_topic.this-controlplane.arn]
  }
}

data "aws_iam_policy_document" "this-controlplane-scaledown-assume" {
  statement {
    sid = "autoscaling"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this-files" {
  version = "2012-10-17"
  statement {
    sid = "log"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.this-files.arn}:log-stream:*"]
  }
  statement {
    sid = "s3"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
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
      "${aws_s3_bucket.this.arn}/files/*",
    ]
  }
}

data "aws_iam_policy_document" "this-lambda-assume" {
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
        var.aws.session_context.issuer_arn,
      ]
    }
  }

  statement {
    sid    = "files"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/files/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.this-files.arn,
      ]
    }
  }

  statement {
    sid    = "ec2"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/controlplane/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.this-controlplane.arn,
        # aws_iam_role.this-worker.arn,
      ]
    }
  }
}

data "aws_iam_policy_document" "this-scaledown" {
  version = "2012-10-17"
  statement {
    sid = "log"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.this-scaledown.arn}:log-stream:*"]
  }
  statement {
    sid = "ssm1"
    actions = [
      "ssm:SendCommand"
    ]
    effect    = "Allow"
    resources = ["arn:${var.aws.partition.id}:ssm:${var.aws.region.name}::document/AWS-RunShellScript"]
  }
  statement {
    sid = "ssm2"
    actions = [
      "ssm:SendCommand"
    ]
    effect = "Allow"
    resources = [
      "arn:${var.aws.partition.id}:ec2:${var.aws.region.name}:${var.aws.caller_identity.account_id}:instance/i-*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/Name"
      values   = ["${var.aws.default_tags.tags["Name"]}-controlplane"]
    }
  }
}
