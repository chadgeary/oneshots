output "this" {
  value = {
    subnets = {
      private = aws_subnet.this_private
      public  = aws_subnet.this_public
    }
    route_tables = {
      private = aws_route_table.this_private
      public  = aws_route_table.this_public
    }
    vpc = aws_vpc.this
  }
}
