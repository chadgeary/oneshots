variable "aws" {
  type = object({
    amis = map(object({
      id = string
    }))
    availability_zones = object({
      names = list(string)
    })
    default_tags = object({
      tags = object({
        Name = string
      })
    })
    nat_instance_types = map(list(string))
  })
}

variable "vpc" {
  type = object({
    subnets = map(map(object({
      arn               = string
      availability_zone = string
      cidr_block        = string
      id                = string
    })))
    route_tables = object({
      private = map(object({
        id = string
      }))
      public = object({
        id = string
      })
    })
    vpc = object({
      id = string
    })
  })
}
