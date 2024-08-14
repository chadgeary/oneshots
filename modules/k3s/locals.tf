locals {
  files = {
    K3S_BIN_ARM64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v1.29.7%2Bk3s1/k3s-arm64"
      prefix = "k3s/k3s-arm64"
    }
    K3S_BIN_AMD64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v1.29.7%2Bk3s1/k3s"
      prefix = "k3s/k3s-amd64"
    }
    K3S_INSTALL = {
      url    = "https://raw.githubusercontent.com/k3s-io/k3s/master/install.sh"
      prefix = "k3s/install.sh"
    }
    K3S_TAR_ARM64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v1.29.7%2Bk3s1/k3s-airgap-images-arm64.tar"
      prefix = "k3s/k3s-airgap-images-arm64.tar"
    }
    K3S_TAR_AMD64 = {
      url    = "https://github.com/k3s-io/k3s/releases/download/v1.29.7%2Bk3s1/k3s-airgap-images-amd64.tar"
      prefix = "k3s/k3s-airgap-images-amd64.tar"
    }
  }
}
