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
        App  = string
        Name = string
      })
    })
    region = object({
      name = string
    })
  })
}

variable "cloudflare" {
  type = object({
    cloudflare_zones = object({
      result = list(object({
        id   = string
        name = string
      }))
    })
  })
}

variable "install" {
  type = object({
    domain = string
    network = object({
      cidr = string
    })
    playbook = string
  })
}