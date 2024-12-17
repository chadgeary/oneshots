resource "aws_iam_role" "this-ebs" {
  name               = "${var.aws.default_tags.tags["Name"]}-ebs"
  assume_role_policy = data.aws_iam_policy_document.this-ebs-trust.json
}

resource "aws_iam_role_policy" "this-ebs" {
  name   = "${var.aws.default_tags.tags["Name"]}-ebs"
  role   = aws_iam_role.this-ebs.id
  policy = data.aws_iam_policy_document.this-ebs.json
}

resource "helm_release" "this-ebs" {
  chart            = "aws-ebs-csi-driver"
  create_namespace = true
  name             = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  version          = "2.38.1"
  values = [yamlencode({
    controller = {
      env = [
        {
          name  = "AWS_REGION"
          value = var.aws.region.name
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
      tolerations = [{
        effect   = "NoSchedule"
        key      = "node-role.kubernetes.io/control-plane"
        operator = "Exists"
      }]
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
          value = var.aws.region.name
        }
      ]
      hostNetwork = true
    }
    storageClasses = [for each in toset(["gp2", "gp3", "io1", "io2", "sc1", "st1", "standard"]) : {
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
