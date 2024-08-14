data "aws_resourcegroupstaggingapi_resources" "this_subnets_public" {
  tag_filter {
    key    = "Name"
    values = ["${var.aws_data.default_tags.tags["Name"]}-public"]
  }
  resource_type_filters = ["ec2:subnet"]
}

data "aws_subnet" "this_public" {
  for_each = toset([for each in data.aws_resourcegroupstaggingapi_resources.this_subnets_public.resource_tag_mapping_list : each.resource_arn])
  id       = split("/", each.key)[1]
}

data "aws_route_table" "this_public" {
  for_each  = data.aws_subnet.this_public
  subnet_id = each.value.id
}
