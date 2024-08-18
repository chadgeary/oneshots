locals {
  image_id       = length(data.aws_ec2_instance_type_offerings.this-arm64.instance_types) > 0 ? var.aws.amis["arm64"].id : var.aws.amis["amd64"].id
  instance_types = length(data.aws_ec2_instance_type_offerings.this-arm64.instance_types) > 0 ? sort(data.aws_ec2_instance_type_offerings.this-arm64.instance_types) : sort(data.aws_ec2_instance_type_offerings.this-amd64.instance_types)
  files = {
    K3S_BIN_ARM64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}%2Bk3s1/k3s-arm64"
      prefix = "files/arm64/k3s"
    }
    K3S_BIN_AMD64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}%2Bk3s1/k3s"
      prefix = "files/amd64/k3s"
    }
    ECR_CRED_AMD64 = {
      url    = "https://storage.googleapis.com/k8s-artifacts-prod/binaries/cloud-provider-aws/v${local.versions["ECR_CRED"]}/linux/amd64/ecr-credential-provider-linux-amd64"
      prefix = "files/amd64/ecr-credential-provider"
    }
    ECR_CRED_ARM64 = {
      url    = "https://storage.googleapis.com/k8s-artifacts-prod/binaries/cloud-provider-aws/v${local.versions["ECR_CRED"]}/linux/arm64/ecr-credential-provider-linux-arm64"
      prefix = "files/arm64/ecr-credential-provider"
    }
    K3S_INSTALL = {
      url    = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"
      prefix = "files/common/install.sh"
    }
    K3S_TAR_ARM64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}%2Bk3s1/k3s-airgap-images-arm64.tar.zst"
      prefix = "files/arm64/images.tar.zst"
    }
    K3S_TAR_AMD64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}%2Bk3s1/k3s-airgap-images-amd64.tar.zst"
      prefix = "files/amd64/images.tar.zst"
    }
  }
  versions = {
    ECR_CRED = "1.29.0"
    K3S      = "1.30.3"
  }
}
