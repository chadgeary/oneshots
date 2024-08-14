output "this" {
  value = {
    subnets = {
      private = aws_subnet.this-private
      public  = aws_subnet.this-public
    }
    route_tables = {
      private = aws_route_table.this-private
      public  = aws_route_table.this-public
    }
    vpc = aws_vpc.this
  }
}
