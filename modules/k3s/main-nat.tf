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

for PORT_FORWARD in 443 6443 80; do
  if iptables -nL -t nat | grep --quiet '^DNAT.*tcp.*dpt:'"$PORT_FORWARD"''; then
    echo "DNAT tcp $PORT_FORWARD exists, skipping"
  else
    iptables -t nat -A PREROUTING -p tcp --dport $PORT_FORWARD -j DNAT --to-destination ${aws_network_interface.this-controlplane.private_ip}:$PORT_FORWARD
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
  for_each                     = toset(["80", "443", "6443"])
  from_port                    = tonumber(each.value)
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.nat.security_group.id
  security_group_id            = aws_security_group.this-controlplane.id
  to_port                      = tonumber(each.value)
}

resource "aws_vpc_security_group_ingress_rule" "this-nat-public" {
  for_each          = toset(["80", "443", "6443"])
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = tonumber(each.value)
  ip_protocol       = "tcp"
  security_group_id = var.nat.security_group.id
  to_port           = tonumber(each.value)
}
