resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.this-assume.json
  description        = "${var.aws.default_tags.tags["Name"]}-nat"
  name               = "${var.aws.default_tags.tags["Name"]}-nat"
  inline_policy {
    name   = "${var.aws.default_tags.tags["Name"]}-nat"
    policy = data.aws_iam_policy_document.this.json
  }
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.aws.default_tags.tags["Name"]}-nat"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "this" {
  description = "${var.aws.default_tags.tags["Name"]}-nat"
  name        = "${var.aws.default_tags.tags["Name"]}-nat"
  tags        = { Name = "${var.aws.default_tags.tags["Name"]}-nat" }
  vpc_id      = var.vpc.vpc.id
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each          = var.vpc.subnets.private
  security_group_id = aws_security_group.this.id

  cidr_ipv4   = each.value.cidr_block
  ip_protocol = "-1"
}

resource "aws_ec2_subnet_cidr_reservation" "this" {
  for_each         = var.vpc.subnets.public
  cidr_block       = "${cidrhost(each.value.cidr_block, 10)}/32"
  subnet_id        = each.value.id
  reservation_type = "explicit"
}

resource "aws_network_interface" "this" {
  for_each          = var.vpc.subnets.public
  subnet_id         = each.value.id
  private_ips       = [cidrhost(each.value.cidr_block, 10)]
  source_dest_check = false
  security_groups   = [aws_security_group.this.id]
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-nat-${each.value.availability_zone}"
  }
}

resource "aws_eip" "this" {
  for_each                  = var.vpc.subnets.public
  domain                    = "vpc"
  network_interface         = aws_network_interface.this[each.key].id
  associate_with_private_ip = tolist(aws_network_interface.this[each.key].private_ips)[0]
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-nat-${each.value.availability_zone}"
  }
}

resource "aws_launch_template" "this" {
  for_each = var.vpc.subnets.public
  image_id = local.ami.id
  name     = "${var.aws.default_tags.tags["Name"]}-nat-${each.value.availability_zone}"
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
    network_interface_id = aws_network_interface.this[each.key].id
  }
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {}))
}

resource "aws_autoscaling_group" "this" {
  for_each                  = var.vpc.subnets.public
  availability_zones        = [var.vpc.subnets.public[each.key].availability_zone]
  capacity_rebalance        = false
  default_instance_warmup   = 60
  desired_capacity          = 1
  health_check_grace_period = 60
  max_size                  = 1
  min_size                  = 1
  name                      = "${var.aws.default_tags.tags["Name"]}-nat-${each.value.availability_zone}"
  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this[each.key].id
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
  for_each               = var.vpc.subnets.public
  route_table_id         = var.vpc.route_tables.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.this[each.key].id
}
