resource "aws_vpc_security_group_ingress_rule" "this-controlplane-nat" {
  for_each                     = toset(["31080", "31443", "6443"])
  from_port                    = tonumber(each.value)
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.nat.security_group.id
  security_group_id            = aws_security_group.this-controlplane.id
  to_port                      = tonumber(each.value)
}

resource "aws_vpc_security_group_ingress_rule" "this-worker-nat" {
  for_each                     = toset(["31080", "31443", "6443"])
  from_port                    = tonumber(each.value)
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.nat.security_group.id
  security_group_id            = aws_security_group.this-worker.id
  to_port                      = tonumber(each.value)
}

resource "aws_vpc_security_group_ingress_rule" "this-nat-public-80" {
  for_each          = toset(var.install.k3s.ingress_cidrs)
  cidr_ipv4         = each.key
  from_port         = 80
  ip_protocol       = "tcp"
  security_group_id = var.nat.security_group.id
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "this-nat-public-443" {
  for_each          = toset(var.install.k3s.ingress_cidrs)
  cidr_ipv4         = each.key
  from_port         = 443
  ip_protocol       = "tcp"
  security_group_id = var.nat.security_group.id
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "this-nat-public-6443" {
  for_each          = toset(var.install.k3s.ingress_cidrs)
  cidr_ipv4         = each.key
  from_port         = 6443
  ip_protocol       = "tcp"
  security_group_id = var.nat.security_group.id
  to_port           = 6443
}