locals {
  ami     = var.aws.amis["24.04"]
  private = cidrsubnet(var.install.network.cidr, 1, 1)
  public  = cidrsubnet(var.install.network.cidr, 1, 0)
}
