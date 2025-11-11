output "this" {
  value = {
    eip               = aws_eip.this
    network_interface = aws_network_interface.this
    security_group    = aws_security_group.this
    subnets = {
      private = aws_subnet.this-private
      public  = aws_subnet.this-public
    }
    vpc = aws_vpc.this
  }
}
