variable "aws" {
  type = object({
    amis = map(object({
      id               = string
      root_device_name = string
    }))
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
    network = object({
      cidr = string
    })
  })
}