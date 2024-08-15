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
    route53 = aws_route53_zone.this
    vpc = aws_vpc.this
  }
}
