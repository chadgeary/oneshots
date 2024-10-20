locals {

  private = cidrsubnet(var.install.vpc.cidr, 1, 0)
  private_nets = { for zone in slice(var.aws.availability_zones.names, 0, var.install.vpc.zones) : zone =>
    {
      cidr = cidrsubnet(local.private, var.install.vpc.zones - 1, index(var.aws.availability_zones.names, zone))
    }
  }

  public = cidrsubnet(var.install.vpc.cidr, 1, 1)
  public_nets = { for zone in slice(var.aws.availability_zones.names, 0, var.install.vpc.zones) : zone =>
    {
      cidr = cidrsubnet(local.public, var.install.vpc.zones - 1, index(var.aws.availability_zones.names, zone))
    }
  }

}