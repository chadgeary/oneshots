resource "aws_vpc" "this" {
  cidr_block           = var.install.network.cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
}

resource "aws_vpc_dhcp_options" "this" {
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "this" {
  vpc_id          = aws_vpc.this.id
  dhcp_options_id = aws_vpc_dhcp_options.this.id
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_vpc_endpoint" "this" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.aws.region.name}.s3"
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-s3"
  }
}

resource "aws_route_table" "this-public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-public"
  }
}

resource "aws_subnet" "this-public" {
  vpc_id            = aws_vpc.this.id
  availability_zone = var.aws.availability_zones.names[0]
  cidr_block        = local.public
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-public"
  }
}

resource "aws_route_table_association" "this-public" {
  subnet_id      = aws_subnet.this-public.id
  route_table_id = aws_route_table.this-public.id
}


resource "aws_route_table" "this-private" {
  vpc_id = aws_vpc.this.id
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-private"
  }
}

resource "aws_subnet" "this-private" {
  vpc_id            = aws_vpc.this.id
  availability_zone = var.aws.availability_zones.names[0]
  cidr_block        = local.private
  tags = {
    "Name" = "${var.aws.default_tags.tags["Name"]}-private"
  }
}

resource "aws_route_table_association" "this-private" {
  subnet_id      = aws_subnet.this-private.id
  route_table_id = aws_route_table.this-private.id
}

resource "aws_vpc_endpoint_route_table_association" "this-private" {
  route_table_id  = aws_route_table.this-private.id
  vpc_endpoint_id = aws_vpc_endpoint.this.id
}