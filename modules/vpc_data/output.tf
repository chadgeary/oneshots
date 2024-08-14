output "this" {
  value = {
    subnets = {
      private = data.aws_subnet.this_private
      public  = data.aws_subnet.this_public
    }
    route_tables = {
      private = data.aws_route_table.this_private
      public  = data.aws_route_table.this_public
    }
    vpc = data.aws_vpc.this
  }
}
