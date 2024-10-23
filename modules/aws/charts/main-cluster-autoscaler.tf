resource "aws_iam_role" "this-cluster-autoscaler" {
  name               = "${var.aws.default_tags.tags["Name"]}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.this-cluster-autoscaler-trust.json
}

resource "aws_iam_role_policy" "this-cluster-autoscaler" {
  name   = "${var.aws.default_tags.tags["Name"]}-cluster-autoscaler"
  role   = aws_iam_role.this-cluster-autoscaler.id
  policy = data.aws_iam_policy_document.this-cluster-autoscaler.json
}

resource "helm_release" "this-cluster-autoscaler" {
  chart      = "cluster-autoscaler"
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  version    = "9.43.1"
  values = [yamlencode({
    autoDiscovery = {
      cloudProvider = "aws"
      clusterName   = var.aws.default_tags.tags["Name"]
      tags          = ["kubernetes.io/nodegroup/${var.aws.default_tags.tags["Name"]}-worker"]
    }
    awsRegion = var.aws.region.name
    extraEnv = {
      "AWS_REGION"                  = var.aws.region.name
      "AWS_ROLE_ARN"                = aws_iam_role.this-cluster-autoscaler.arn
      "AWS_WEB_IDENTITY_TOKEN_FILE" = "/var/run/secrets/kubernetes.io/irsa/token"
    }
    extraVolumeMounts = [{
      mountPath = "/var/run/secrets/kubernetes.io/irsa/"
      name      = "irsa"
    }]
    extraVolumes = [{
      name = "irsa"
      projected = {
        sources = [{
          serviceAccountToken = {
            audience          = var.aws.default_tags.tags["Name"]
            expirationSeconds = 43200
            path              = "token"
          }
        }]
      }
    }]
    rbac = {
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this-cluster-autoscaler.arn
        }
      }
    }
    tolerations = [{ operator = "Exists" }]
  })]
}
