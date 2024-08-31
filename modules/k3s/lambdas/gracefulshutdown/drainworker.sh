#!/usr/bin/env bash

METADATA_TOKEN="$(curl -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 300' http://169.254.169.254/latest/api/token)"
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
KUBECONFIG=/etc/rancher/k3s/k3s.yaml
export METADATA_TOKEN INSTANCE_ID KUBECONFIG

if [ "$INSTANCE_ID" == "$WORKER_ID" ]; then
  echo "INFO $INSTANCE_ID == $WORKER_ID, skipping"
else
  WORKER_NAME=$(kubectl get nodes \
    -l node.kubernetes.io/id="$WORKER_ID" \
    -o jsonpath='{.items[*].metadata.name}')

  kubectl \
    drain "$WORKER_NAME" \
    --delete-emptydir-data \
    --force \
    --grace-period=30 \
    --ignore-daemonsets

  kubectl \
    delete node \
    "$WORKER_NAME"
fi
