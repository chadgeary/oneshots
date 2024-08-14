
resource "aws_route_table" "this-private" {
  for_each = local.private_nets
  vpc_id   = aws_vpc.this.id
  tags = {
    "Name" = "${var.aws_data.default_tags.tags["Name"]}-private"
  }
}

resource "aws_subnet" "this-private" {
  for_each          = local.private_nets
  vpc_id            = aws_vpc.this.id
  availability_zone = each.key
  cidr_block        = each.value.cidr
  tags = {
    "Name" = "${var.aws_data.default_tags.tags["Name"]}-private"
  }
}

resource "aws_route_table_association" "this-private" {
  for_each       = local.private_nets
  subnet_id      = aws_subnet.this-private[each.key].id
  route_table_id = aws_route_table.this-private[each.key].id
}