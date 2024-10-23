resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.this-assume.json
  description        = "${var.aws.default_tags.tags["Name"]}-nat"
  name               = "${var.aws.default_tags.tags["Name"]}-nat"
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.aws.default_tags.tags["Name"]}-nat"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.aws.default_tags.tags["Name"]}-nat"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "this" {
  description = "${var.aws.default_tags.tags["Name"]}-nat"
  name        = "${var.aws.default_tags.tags["Name"]}-nat"
  tags        = { Name = "${var.aws.default_tags.tags["Name"]}-nat" }
  vpc_id      = aws_vpc.this.id
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = local.private
  ip_protocol       = "-1"
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
    "Name" = "${var.aws.default_tags.tags["Name"]}-nat"
  }
}

resource "aws_eip" "this" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.this.id
  associate_with_private_ip = tolist(aws_network_interface.this.private_ips)[0]
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-nat"
  }
}

resource "aws_launch_template" "this" {
  image_id = local.ami.id
  name     = "${var.aws.default_tags.tags["Name"]}-nat"
  block_device_mappings {
    device_name = local.ami.root_device_name
    ebs {
      volume_size = 2
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }
  network_interfaces {
    network_interface_id = aws_network_interface.this.id
  }
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", { aws = var.aws, controlplane = cidrhost(local.private, 10), private = local.private }))
}

resource "aws_autoscaling_group" "this" {
  availability_zones        = [var.aws.availability_zones.names[0]]
  capacity_rebalance        = false
  default_instance_warmup   = 60
  desired_capacity          = 1
  health_check_grace_period = 60
  max_size                  = 1
  min_size                  = 1
  name                      = "${var.aws.default_tags.tags["Name"]}-nat"
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = local.instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }
  tag {
    key                 = "Name"
    value               = "${var.aws.default_tags.tags["Name"]}-nat"
    propagate_at_launch = true
  }
}

resource "aws_route" "this" {
  route_table_id         = aws_route_table.this-private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.this.id
}
