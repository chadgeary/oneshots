variable "aws" {
  type = object({
    availability_zones = object({
      names = list(string)
    })
    default_tags = object({
      tags = object({
        Name = string
      })
    })
    region = object({
      name = string
    })
  })
}

variable "install" {
  type = object({
    vpc = object({
      cidr  = string
      zones = number
    })
  })
}
