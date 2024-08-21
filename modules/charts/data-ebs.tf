data "aws_iam_policy_document" "this-ebs" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
    ]
  }

  statement {
    effect = "Allow"
    resources = [
      "arn:${var.aws.partition.id}:ec2:${var.aws.region.name}:${var.aws.caller_identity.account_id}:snapshot/*",
      "arn:${var.aws.partition.id}:ec2:${var.aws.region.name}:${var.aws.caller_identity.account_id}:volume/*",
    ]

    actions = ["ec2:CreateTags"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateSnapshot",
        "CreateVolume",
      ]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:CreateVolume"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/csi"
      values   = [var.aws.default_tags.tags["Name"]]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:DeleteVolume"]

    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/csi"
      values   = [var.aws.default_tags.tags["Name"]]
    }
  }
}

data "aws_iam_policy_document" "this-ebs-trust" {
  statement {
    sid     = "ebs"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.cluster.idp.arn]
    }
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "${replace(var.cluster.idp.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}
