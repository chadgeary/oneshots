data "aws_resourcegroupstaggingapi_resources" "this_vpc" {
  tag_filter {
    key    = "Name"
    values = [var.aws_data.default_tags.tags["Name"]]
  }
  resource_type_filters = ["ec2:vpc"]
}

data "aws_vpc" "this" {
  id = split("/", [for each in data.aws_resourcegroupstaggingapi_resources.this_vpc.resource_tag_mapping_list : each.resource_arn][0])[1]
}
