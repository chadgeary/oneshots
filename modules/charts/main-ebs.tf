resource "aws_iam_role" "this-ebs" {
  name               = "${var.aws.default_tags.tags["Name"]}-ebs"
  assume_role_policy = data.aws_iam_policy_document.this-ebs-trust.json
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-ebs"
    policy = data.aws_iam_policy_document.this-ebs.json
  }
}

resource "helm_release" "this" {
  chart            = "https://github.com/kubernetes-sigs/aws-ebs-csi-driver/releases/download/helm-chart-aws-ebs-csi-driver-2.33.0/aws-ebs-csi-driver-2.33.0.tgz"
  create_namespace = true
  name             = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  values = [yamlencode({
    controller = {
      env = [
        {
          name  = "AWS_REGION"
          value = "us-east-2"
        },
        {
          name  = "AWS_ROLE_ARN"
          value = aws_iam_role.this-ebs.arn
        },
        {
          name  = "AWS_WEB_IDENTITY_TOKEN_FILE"
          value = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        }
      ]
      replicaCount = 1
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.this-ebs.arn
        }
      }
      volumeMounts = [{
        mountPath = "/var/run/secrets/kubernetes.io/serviceaccount/"
        name      = "serviceaccount"
      }]
      volumes = [{
        name = "serviceaccount"
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
    }
    node = {
      env = [
        {
          name  = "AWS_REGION"
          value = "us-east-2"
        }
      ]
      hostNetwork = true
    }
    storageClasses = [for each in toset(["gp2", "gp3", "io2", "sc1", "st1"]) : {
      allowVolumeExpansion = true
      name                 = each
      parameters = {
        tagSpecification_1 = "csi=${var.aws.default_tags.tags["Name"]}"
        tagSpecification_2 = "pvcnamespace={{ .PVCNamespace }}"
        tagSpecification_3 = "pvcname={{ .PVCName }}"
        tagSpecification_4 = "pvname={{ .PVName }}"
        type               = each
      }
      provisioner       = "ebs.csi.aws.com"
      reclaimPolicy     = "Delete"
      volumeBindingMode = "WaitForFirstConsumer"
    }]
  })]
}
