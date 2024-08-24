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
  /usr/local/bin/k3s-killall.sh
}

UNMOUNT_VOL() {
  echo "$INSTANCE_IP" > /var/lib/rancher/k3s/node.old

  until umount /var/lib/rancher/k3s; do
    sleep 1
  done

  aws ec2 detach-volume \
    --device "xvdc" \
    --instance-id "$INSTANCE_ID" \
    --volume-id "$VOLUME"

  until [ ! -e "/dev/xvdc" ]; do
    sleep 1
  done
}

ASG_NOTIFY() {
  aws autoscaling complete-lifecycle-action \
    --auto-scaling-group-name "$NAME-controlplane" \
    --instance-id "$INSTANCE_ID" \
    --lifecycle-action-result "CONTINUE" \
    --lifecycle-hook-name "$NAME-controlplane" \
    --region "$INSTANCE_REGION"
}

ASG_DETACH() {
  aws autoscaling detach-instances \
    --instance-ids "$INSTANCE_ID" \
    --auto-scaling-group-name "$NAME-controlplane" \
    --no-should-decrement-desired-capacity
}

SHUTDOWN_NOW() {
  aws ec2 terminate-instances \
    --instance-ids "$INSTANCE_ID"
  shutdown -h now &
}

EC2_METADATA
GET_ENV
ETCD_SNAPSHOT
NODE_DRAIN
UNMOUNT_VOL
if [ "$EVENT_TYPE" == "lifecyclehook" ]; then
  ASG_NOTIFY
elif [ "$EVENT_TYPE" == "spotinterruption" ]; then
  ASG_DETACH
fi
SHUTDOWN_NOW
