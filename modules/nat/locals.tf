locals {
  image_id       = length(var.aws.nat_instance_types["arm64"]) > 0 ? var.aws.amis["arm64"].id : var.aws.amis["amd64"].id
  instance_types = length(var.aws.nat_instance_types["arm64"]) > 0 ? var.aws.nat_instance_types["arm64"] : var.aws.nat_instance_types["amd64"]
  user_data      = <<EOF
#!/usr/bin/env bash
METADATA_TOKEN="$(curl -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 300' http://169.254.169.254/latest/api/token)"
ENI_MAC="$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" http://169.254.169.254/latest/meta-data/mac)"
ENI_IFACE="$(curl -H "X-aws-ec2-metadata-token: $METADATA_TOKEN" http://169.254.169.254/latest/meta-data/network/interfaces/macs/$ENI_MAC/interface-id)"
ENI_IFACE_NAME="$(ip link show dev $ENI_IFACE | awk -F': ' 'NR==1 { print $2 }')"

# forwarding
sysctl -q -w net.ipv4.ip_forward=1

# reverse path
for i in $(find /proc/sys/net/ipv4/conf/ -name rp_filter) ; do
  echo 0 > $i;
done

# NAT route
dnf install -y iptables
iptables -t nat -F
iptables -t nat -A POSTROUTING -o "$ENI_IFACE_NAME" -j MASQUERADE -m comment --comment "NAT Gateway"
EOF
}
