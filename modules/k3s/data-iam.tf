data "aws_iam_policy_document" "this-assume" {
  for_each = toset(["autoscaling", "ec2", "lambda"])
  statement {
    sid = each.key
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["${each.key}.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this-controlplane" {
  version = "2012-10-17"
  statement {
    sid = "asg"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DetachInstances",
    ]
    effect = "Allow"
    resources = [
      "arn:${var.aws.partition.id}:autoscaling:${var.aws.region.name}:${var.aws.caller_identity.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.aws.default_tags.tags["Name"]}-controlplane"
    ]
  }
  statement {
    sid = "ebs"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]
    effect = "Allow"
    resources = [
      "arn:${var.aws.partition.id}:ec2:${var.aws.region.name}:${var.aws.caller_identity.account_id}:instance/i-*",
      "arn:${var.aws.partition.id}:ec2:${var.aws.region.name}:${var.aws.caller_identity.account_id}:volume/vol-*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Name"
      values   = ["${var.aws.default_tags.tags["Name"]}-controlplane"]
    }
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
    sid = "eni1"
    actions = [
      "ec2:DescribeNetworkInterfaces",
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "eni2"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:TerminateInstances",
    ]
    effect = "Allow"
    resources = [
      "arn:${var.aws.partition.id}:ec2:${var.aws.region.name}:${var.aws.caller_identity.account_id}:instance/i-*",
      aws_network_interface.this-controlplane.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Name"
      values   = ["${var.aws.default_tags.tags["Name"]}-controlplane"]
    }
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
    resources = ["${aws_s3_bucket.this.arn}/files/*"]
    effect    = "Allow"
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
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/controlplane/*",
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "this-controlplane-autoscaling" {
  version = "2012-10-17"
  statement {
    sid = "sns"
    actions = [
      "sns:Publish"
    ]
    effect    = "Allow"
    resources = [aws_sns_topic.this-controlplane-autoscaling.arn]
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
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/files/*",
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.this-lambdas["files"].arn,
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
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
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
  statement {
    sid    = "watch"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/controlplane/*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.this-lambdas["watch"].arn,
      ]
    }
  }
  statement {
    sid = "public"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.this.arn}/controlplane/oidc/*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingObjectTag/public"
      values   = ["true"]
    }
  }
}

data "aws_iam_policy_document" "this-lambdas" {
  for_each = local.lambdas
  version  = "2012-10-17"
  statement {
    sid = "log"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.this-lambdas[each.key].arn}:log-stream:*"]
  }
  dynamic "statement" {
    for_each = each.key == "files" ? [1] : []
    content {
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
      ]
      effect = "Allow"
      resources = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/files/*",
      ]
    }
  }
  dynamic "statement" {
    for_each = each.key == "watch" ? [1] : []
    content {
      sid = "s3"
      actions = [
        "s3:GetObject",
      ]
      effect = "Allow"
      resources = [
        "${aws_s3_bucket.this.arn}/controlplane/*"
      ]
    }
  }
  dynamic "statement" {
    for_each = each.key == "gracefulshutdown" ? [1] : []
    content {
      sid = "ssm1"
      actions = [
        "ssm:SendCommand"
      ]
      effect    = "Allow"
      resources = ["arn:${var.aws.partition.id}:ssm:${var.aws.region.name}::document/AWS-RunShellScript"]
    }
  }
  dynamic "statement" {
    for_each = each.key == "gracefulshutdown" ? [1] : []
    content {
      sid = "ssm2"
      actions = [
        "ssm:SendCommand"
      ]
      effect    = "Allow"
      resources = ["arn:${var.aws.partition.id}:ec2:${var.aws.region.name}:${var.aws.caller_identity.account_id}:instance/i-*"]
      condition {
        test     = "StringEquals"
        variable = "ssm:resourceTag/Name"
        values   = ["${var.aws.default_tags.tags["Name"]}-controlplane"]
      }
    }
  }
}
