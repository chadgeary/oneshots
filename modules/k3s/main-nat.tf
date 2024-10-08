resource "aws_ssm_association" "this-nat" {
  name = "AWS-RunShellScript"
  parameters = {
    commands = <<EOF
until command -v iptables; do
  sleep 1
done

until iptables -nL -t nat | grep --quiet 'NAT Gateway'; do
  sleep 1
done

if iptables -nL -t nat | grep --quiet '^ACCEPT.*all.*'; then
  echo "ACCEPT all SOURCE ${cidrsubnet(var.vpc.vpc.cidr_block, 1, 0)} exists, skipping"
else
  iptables -t nat -A PREROUTING -s ${cidrsubnet(var.vpc.vpc.cidr_block, 1, 0)} -j ACCEPT
fi

declare -a PORT_FORWARDS=("80:31080" "443:31443" "6443:6443")

for PORT_FORWARD in "$${PORT_FORWARDS[@]}"; do
  SRC_PORT=$(echo "$PORT_FORWARD" | awk -F':' '{print $1}' )
  DST_PORT=$(echo "$PORT_FORWARD" | awk -F':' '{print $2}' )
  if iptables -nL -t nat | grep --quiet '^DNAT.*tcp.*dpt:'"$DST_PORT"''; then
    echo "DNAT tcp $DST_PORT exists, skipping"
  else
    iptables -t nat -A PREROUTING -p tcp --dport $SRC_PORT -j DNAT --to-destination ${aws_network_interface.this-controlplane.private_ip}:$DST_PORT
  fi
done
EOF
  }
  targets {
    key    = "tag:Name"
    values = ["${var.aws.default_tags.tags["Name"]}-nat"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "this-controlplane-nat" {
  for_each                     = toset(["31080", "31443", "6443"])
  from_port                    = tonumber(each.value)
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.nat.security_group.id
  security_group_id            = aws_security_group.this-controlplane.id
  to_port                      = tonumber(each.value)
}

resource "aws_vpc_security_group_ingress_rule" "this-nat-public" {
  for_each          = toset(var.install.k3s.ingress_cidrs)
  cidr_ipv4         = each.key
  ip_protocol       = "-1"
  security_group_id = var.nat.security_group.id
}
