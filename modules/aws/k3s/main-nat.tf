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
