resource "aws_ssm_association" "this-nat" {
  name = "AWS-RunShellScript"
  parameters = {
    commands = <<EOF
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination ${aws_network_interface.this-controlplane.private_ip}:443
iptables -t nat -A PREROUTING -p tcp --dport 6443 -j DNAT --to-destination ${aws_network_interface.this-controlplane.private_ip}:6443
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination ${aws_network_interface.this-controlplane.private_ip}:80
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