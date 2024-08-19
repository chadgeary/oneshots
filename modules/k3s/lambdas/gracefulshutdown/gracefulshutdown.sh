#!/usr/bin/env bash

EC2_METADATA() {
  METADATA_TOKEN="$(curl -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 300' http://169.254.169.254/latest/api/token)"
  INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
  INSTANCE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
  INSTANCE_REGION=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
}

GET_ENV() {
  source /opt/k3s.env
  KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  export KUBECONFIG
}

ETCD_SNAPSHOT() {
  k3s etcd-snapshot save \
    --s3 \
    --s3-bucket "$BUCKET" \
    --s3-folder controlplane/snapshots/ \
    --s3-region "$INSTANCE_REGION"
}

NODE_DRAIN() {
  kubectl \
    drain "$INSTANCE_IP" \
    --delete-emptydir-data \
    --force \
    --grace-period=30 \
    --ignore-daemonsets
}

K3S_KILL() {
  kubectl get node -o name "$INSTANCE_IP" | \
    xargs -I {} kubectl patch {} -p '{"metadata":{"finalizers":[]}}' --type=merge
  kubectl \
    delete node "$INSTANCE_IP" &
  /usr/local/bin/k3s-killall.sh
}

UNMOUNT_VOL() {
  umount /var/lib/rancher/k3s
  aws ec2 detach-volume \
    --device "xvdc" \
    --instance-id "$INSTANCE_ID" \
    --volume-id "$VOLUME"

  until [ ! -e "/dev/xvdc" ]; do
    sleep 1
  done
}

DETACH_ENI() {
  ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --filters Name=private-ip-address,Values="$PRIVATE_IP" --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text)
  aws ec2 detach-network-interface \
    --attachment-id "$ATTACHMENT_ID"
}

ASG_NOTIFY() {
  sleep 5
  aws autoscaling complete-lifecycle-action \
    --auto-scaling-group-name "$NAME-controlplane" \
    --instance-id "$INSTANCE_ID" \
    --lifecycle-action-result "CONTINUE" \
    --lifecycle-hook-name "$NAME-controlplane" \
    --region "$INSTANCE_REGION"
}

ASG_DETACH() {
  sleep 5
  aws autoscaling detach-instances \
    --instance-ids "$INSTANCE_ID" \
    --auto-scaling-group-name "$NAME-controlplane" \
    --no-should-decrement-desired-capacity
  shutdown -h now
}

EC2_METADATA
GET_ENV
ETCD_SNAPSHOT
NODE_DRAIN
K3S_KILL
UNMOUNT_VOL
DETACH_ENI
if [ "$EVENT_TYPE" == "lifecyclehook" ]; then
  ASG_NOTIFY &
elif [ "$EVENT_TYPE" == "spotinterruption" ]; then
  ASG_DETACH &
fi
