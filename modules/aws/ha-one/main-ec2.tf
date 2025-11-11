resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.this-assume.json
  description        = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
  name               = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "this" {
  description = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
  name        = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
  tags        = { Name = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}" }
  vpc_id      = aws_vpc.this.id
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each          = toset(["80", "443"])
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = tonumber(each.key)
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.this.id
  to_port           = tonumber(each.key)
}

resource "aws_ec2_subnet_cidr_reservation" "this" {
  cidr_block       = "${cidrhost(local.public, 10)}/32"
  subnet_id        = aws_subnet.this-public.id
  reservation_type = "explicit"
}

resource "aws_network_interface" "this" {
  subnet_id         = aws_subnet.this-public.id
  private_ips       = [cidrhost(local.public, 10)]
  source_dest_check = false
  security_groups   = [aws_security_group.this.id]
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
  }
}

resource "aws_instance" "this" {
  availability_zone    = var.aws.availability_zones.names[0]
  ami                  = local.ami.id
  instance_type        = "t3a.medium"
  iam_instance_profile = aws_iam_instance_profile.this.name
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }
  primary_network_interface {
    network_interface_id = aws_network_interface.this.id
  }
  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }
  user_data_base64 = base64encode(templatefile("${path.module}/user_data.sh.tftpl", { aws = var.aws, playbook = base64gzip(file(var.install.playbook)), domain = local.domain.name }))
}

resource "aws_eip" "this" {
  instance                  = aws_instance.this.id
  domain                    = "vpc"
  network_interface         = aws_network_interface.this.id
  associate_with_private_ip = tolist(aws_network_interface.this.private_ips)[0]
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-${var.aws.default_tags.tags["App"]}"
  }
}