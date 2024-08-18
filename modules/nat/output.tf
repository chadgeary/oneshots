output "this" {
  value = {
    eip               = aws_eip.this
    network_interface = aws_network_interface.this
    security_group    = aws_security_group.this
  }
}
