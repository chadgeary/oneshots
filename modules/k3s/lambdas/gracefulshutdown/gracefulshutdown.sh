#!/usr/bin/env bash

EC2_METADATA() {
  METADATA_TOKEN="$(curl -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 300' http://169.254.169.254/latest/api/token)"
  INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
  INSTANCE_REGION=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
}

GET_ENV() {
  source /opt/k3s.env
}

INSTANCE_NAME() {
  if [ "$INSTANCE_REGION" == "us-east-1" ]; then
    NODE_NAME="$(hostname).ec2.internal"
  else
    NODE_NAME="$(hostname).$INSTANCE_REGION.compute.internal"
  fi
}

ETCD_SNAPSHOT() {
  k3s etcd-snapshot save \
    --s3 \
    --s3-bucket "$BUCKET" \
    --s3-folder controlplane/snapshots/ \
    --s3-region "$INSTANCE_REGION"
}

NODE_DRAIN() {
  KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl \
    drain "$NODE_NAME" \
    --force \
    --grace-period=60 \
    --ignore-daemonsets
}

K3S_KILL() {
  KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl \
    delete node "$NODE_NAME"
  /usr/local/bin/k3s-killall.sh
}

UNMOUNT_ETCD() {
  umount /var/lib/rancher/k3s
  aws ec2 detach-volume \
    --device "xvdc" \
    --instance-id "$INSTANCE_ID" \
    --volume-id "$VOLUME"

  until [ ! -e "/dev/xvdc" ]; do
    sleep 1
  done
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
INSTANCE_NAME
ETCD_SNAPSHOT
NODE_DRAIN
K3S_KILL
UNMOUNT_ETCD
if [ "$EVENT_TYPE" == "lifecyclehook" ]; then
  ASG_NOTIFY &
elif [ "$EVENT_TYPE" == "spotinterruption" ]; then
  ASG_DETACH &
fi
