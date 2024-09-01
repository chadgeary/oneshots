resource "aws_iam_role" "this-aws-ccm" {
  name               = "${var.aws.default_tags.tags["Name"]}-aws-ccm"
  assume_role_policy = data.aws_iam_policy_document.this-aws-ccm-trust.json
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-aws-ccm"
    policy = data.aws_iam_policy_document.this-aws-ccm.json
  }
}

resource "helm_release" "this-aws-ccm" {
  chart            = "aws-cloud-controller-manager"
  create_namespace = true
  name             = "aws-cloud-controller-manager"
  namespace        = "kube-system"
  repository       = "https://kubernetes.github.io/cloud-provider-aws"
  version          = "0.0.8"
  values = [yamlencode({
    args = [
      "--v=2",
      "--cloud-provider=aws",
      "--configure-cloud-routes=false",
    ]
    env = [
      {
        name  = "AWS_REGION"
        value = var.aws.region.name
      },
      {
        name  = "AWS_ROLE_ARN"
        value = aws_iam_role.this-aws-ccm.arn
      },
      {
        name  = "AWS_WEB_IDENTITY_TOKEN_FILE"
        value = "/var/run/secrets/kubernetes.io/irsa/token"
      }
    ]
    hostNetworking = true
    image = {
      tag = "v1.30.3"
    }
    nodeSelector = {
      "node-role.kubernetes.io/control-plane" = "true"
    }
    resources = {
      limits = {
        cpu = "500m"
      }
      requests = {
        cpu = "10m"
      }
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.this-aws-ccm.arn
      }
    }
    tolerations = [{
      effect   = "NoSchedule"
      key      = "node-role.kubernetes.io/control-plane"
      operator = "Exists"
    }]
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
  })]
}
