resource "aws_route_table" "this-public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
    "Name" = "${var.aws_data.default_tags.tags["Name"]}-public"
  }
}

resource "aws_subnet" "this-public" {
  for_each          = local.public_nets
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value.cidr
  tags = {
    "Name" = "${var.aws_data.default_tags.tags["Name"]}-public"
  }
}

resource "aws_route_table_association" "this-public" {
  for_each       = local.public_nets
  subnet_id      = aws_subnet.this-public[each.key].id
  route_table_id = aws_route_table.this-public.id
}
