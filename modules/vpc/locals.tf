locals {

  private_nets = { for zone in slice(var.aws.availability_zones.names, 0, var.install.vpc.zones) : zone =>
    {
      cidr = cidrsubnet(cidrsubnet(var.install.vpc.cidr, 1, 0), var.install.vpc.zones - 1, index(var.aws.availability_zones.names, zone))
    }
  }

  public_nets = { for zone in slice(var.aws.availability_zones.names, 0, var.install.vpc.zones) : zone =>
    {
      cidr = cidrsubnet(cidrsubnet(var.install.vpc.cidr, 1, 1), var.install.vpc.zones - 1, index(var.aws.availability_zones.names, zone))
    }
  }

}