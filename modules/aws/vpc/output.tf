output "this" {
  value = {
    networks = {
      private = local.private
      public  = local.public
      vpc     = var.install.vpc.cidr
    }
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
