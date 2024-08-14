variable "aws_data" {
  type = object({
    amis = map(object({
      id = string
    }))
    availability_zones = object({
      names = list(string)
    })
    nat_instance_types = map(list(string))
  })
}

variable "vpc_data" {
  type = object({
    subnets = object({
      private = map(object({
        arn               = string
        availability_zone = string
        cidr_block        = string
        id                = string
      }))
      public = map(object({
        availability_zone = string
        cidr_block        = string
        id                = string
      }))
    })
    route_tables = object({
      private = map(object({
        id = string
      }))
      public = map(object({
        id = string
      }))
    })
    vpc = object({
      id = string
    })
  })
}

variable "install" {
  type = object({
    name = string
    vpc = object({
      zones = number
    })
  })
}