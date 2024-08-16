locals {
  versions = {
    ECR_CRED = "1.29.0"
    K3S      = "1.30.3"
  }
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

  image_id       = length(var.aws.k3s_instance_types["arm64"]) > 0 ? var.aws.amis["arm64"].id : var.aws.amis["amd64"].id
  instance_types = length(var.aws.k3s_instance_types["arm64"]) > 0 ? var.aws.k3s_instance_types["arm64"] : var.aws.k3s_instance_types["amd64"]

  user_data = <<EOF
#!/usr/bin/env bash
METADATA_TOKEN="$(curl -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 300' http://169.254.169.254/latest/api/token)"
INSTANCE_ARCH=$(if [ $(uname -m) == "x86_64" ]; then echo "amd64"; else echo "arm64"; fi)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
INSTANCE_INDEX=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/ami-launch-index)
INSTANCE_IP=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_REGION=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
INSTANCE_TYPE=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
INSTANCE_ZONE=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)

if [ "$INSTANCE_REGION" == "us-east-1" ]; then
  NODE_NAME="$(hostname).ec2.internal"
else
  NODE_NAME="$(hostname).$INSTANCE_REGION.compute.internal"
fi

until host controlplane.${var.aws.default_tags.tags["Name"]}.internal | grep --quiet $INSTANCE_IP; do
  sleep 1
done

if [ $(aws s3 ls s3://${aws_s3_bucket.this.id}/controlplane/ | wc -l) == "0" ] && [ $INSTANCE_INDEX == "0" ]; then
  INIT_ARG="--cluster-init"
else
  until aws s3 ls s3://${aws_s3_bucket.this.id}/controlplane/SERVER_NODE_TOKEN | grep --quiet SERVER_NODE_TOKEN; do
    sleep 1
  done
  SERVER_NODE_TOKEN=$(aws s3 cp s3://${aws_s3_bucket.this.id}/controlplane/SERVER_NODE_TOKEN -)
  INIT_ARG="--server https://controlplane.${var.aws.default_tags.tags["Name"]}.internal:6443 -t $${SERVER_NODE_TOKEN}"
fi

for DIR in \
  /etc/rancher/k3s \
  /var/lib/rancher/credentialprovider/bin \
  /var/lib/rancher/k3s/agent/images
do
  install -Dd -m=0750 $DIR
done

# sed -i "s/^MACAddressPolicy=.*/MACAddressPolicy=none/" /usr/lib/systemd/network/99-default.link || true

tee /var/lib/rancher/credentialprovider/config.yaml << EOM
apiVersion: kubelet.config.k8s.io/v1
kind: CredentialProviderConfig
providers:
  - name: ecr-credential-provider
    matchImages:
      - "*.dkr.ecr.*.amazonaws.com"
      - "*.dkr.ecr.*.amazonaws.com.cn"
      - "*.dkr.ecr-fips.*.amazonaws.com"
      - "*.dkr.ecr.us-iso-east-1.c2s.ic.gov"
      - "*.dkr.ecr.us-isob-east-1.sc2s.sgov.gov"
    defaultCacheDuration: "12h"
    apiVersion: credentialprovider.kubelet.k8s.io/v1
EOM

tee /etc/rancher/k3s/resolv.conf << EOM
nameserver 169.254.169.253
EOM

tee -a /etc/hosts << EOM
$INSTANCE_IP localhost
$INSTANCE_IP $(hostname)
$INSTANCE_IP $NODE_NAME
EOM

aws s3 cp s3://${aws_s3_bucket.this.id}/files/$INSTANCE_ARCH/k3s /usr/local/bin/ && chmod +x /usr/local/bin/k3s
aws s3 cp s3://${aws_s3_bucket.this.id}/files/$INSTANCE_ARCH/ecr-credential-provider /var/lib/rancher/credentialprovider/bin/ && chmod +x /var/lib/rancher/credentialprovider/bin/ecr-credential-provider
aws s3 cp s3://${aws_s3_bucket.this.id}/files/common/install.sh /usr/local/bin/ && chmod +x /usr/local/bin/install.sh
aws s3 cp s3://${aws_s3_bucket.this.id}/files/$INSTANCE_ARCH/images.tar.zst /var/lib/rancher/k3s/agent/images/k3s-airgap-images.tar.zst

INSTALL_K3S_SKIP_DOWNLOAD=true /usr/local/bin/install.sh \
  server $INIT_ARG \
  --advertise-address $INSTANCE_IP \
  --cluster-cidr=172.19.0.0/16 \
  --cluster-dns=172.20.0.10 \
  --disable-cloud-controller \
  --disable=servicelb \
  --disable=traefik \
  --kube-apiserver-arg api-audiences=${var.aws.default_tags.tags["Name"]} \
  --kube-apiserver-arg service-account-issuer=https://s3.$INSTANCE_REGION.amazonaws.com/${var.aws.default_tags.tags["Name"]}-pub/oidc \
  --kube-apiserver-arg service-account-jwks-uri=https://s3.$INSTANCE_REGION.amazonaws.com/${var.aws.default_tags.tags["Name"]}-pub/oidc/openid/v1/jwks \
  --node-ip $INSTANCE_IP \
  --node-label node.kubernetes.io/instance-type=$INSTANCE_TYPE \
  --node-label node.kubernetes.io/id=$INSTANCE_ID \
  --node-label topology.kubernetes.io/region=$INSTANCE_REGION \
  --node-label topology.kubernetes.io/zone=$INSTANCE_ZONE \
  --node-name $NODE_NAME \
  --resolv-conf /etc/rancher/k3s/resolv.conf \
  --service-cidr=172.20.0.0/16 \
  --tls-san=controlplane.${var.aws.default_tags.tags["Name"]}.internal

if [ "$${INIT_ARG:-}" == "--cluster-init" ]; then
  until [ -f /etc/rancher/k3s/k3s.yaml ]; do
    sleep 1
  done
  aws s3 cp /etc/rancher/k3s/k3s.yaml s3://${aws_s3_bucket.this.id}/controlplane/config

  until [ -f /var/lib/rancher/k3s/server/token ]; do
    sleep 1
  done
  aws s3 cp /var/lib/rancher/k3s/server/token s3://${aws_s3_bucket.this.id}/controlplane/SERVER_NODE_TOKEN

  until [ -f /var/lib/rancher/k3s/server/agent-token ]; do
    sleep 1
  done
  aws s3 cp /var/lib/rancher/k3s/server/agent-token s3://${aws_s3_bucket.this.id}/controlplane/AGENT_NODE_TOKEN
fi

EOF
}
