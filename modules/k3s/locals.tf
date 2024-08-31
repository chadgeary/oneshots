locals {
  control_plane_ami = length([for each in data.aws_ec2_instance_type.this-controlplane : each if contains(each.supported_architectures, "arm64")]) > 0 ? var.aws.amis["minimal-arm64"] : var.aws.amis["minimal-amd64"]
  worker_ami        = length([for each in data.aws_ec2_instance_type.this-worker : each if contains(each.supported_architectures, "arm64")]) > 0 ? var.aws.amis["minimal-arm64"] : var.aws.amis["minimal-amd64"]
  files = {
    K3S_BIN_ARM64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}/k3s-arm64"
      prefix = "files/arm64/k3s"
    }
    K3S_BIN_AMD64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}/k3s"
      prefix = "files/amd64/k3s"
    }
    ECR_CRED_AMD64 = {
      url    = "https://artifacts.k8s.io/binaries/cloud-provider-aws/v${local.versions["ECR_CRED"]}/linux/amd64/ecr-credential-provider-linux-amd64"
      prefix = "files/amd64/ecr-credential-provider"
    }
    ECR_CRED_ARM64 = {
      url    = "https://artifacts.k8s.io/binaries/cloud-provider-aws/v${local.versions["ECR_CRED"]}/linux/arm64/ecr-credential-provider-linux-arm64"
      prefix = "files/arm64/ecr-credential-provider"
    }
    K3S_INSTALL = {
      url    = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"
      prefix = "files/common/install.sh"
    }
    K3S_TAR_ARM64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}/k3s-airgap-images-arm64.tar.zst"
      prefix = "files/arm64/images.tar.zst"
    }
    K3S_TAR_AMD64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v${local.versions["K3S"]}/k3s-airgap-images-amd64.tar.zst"
      prefix = "files/amd64/images.tar.zst"
    }
    SSM_RPM_ARM64 = {
      url    = "https://s3.${var.aws.region.name}.amazonaws.com/amazon-ssm-${var.aws.region.name}/latest/linux_arm64/amazon-ssm-agent.rpm"
      prefix = "files/arm64/amazon-ssm-agent.rpm"
    }
    SSM_RPM_AMD64 = {
      url    = "https://s3.${var.aws.region.name}.amazonaws.com/amazon-ssm-${var.aws.region.name}/latest/linux_amd64/amazon-ssm-agent.rpm"
      prefix = "files/amd64/amazon-ssm-agent.rpm"
    }
  }
  versions = {
    ECR_CRED = "1.29.0"
    K3S      = "1.30.3+k3s1"
  }
}
