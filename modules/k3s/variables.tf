variable "aws" {
  type = object({
    amis = map(object({
      id = string
    }))
    default_tags = object({
      tags = object({
        Name = string
      })
    })
    k3s_instance_types = map(list(string))
    partition = object({
      id = string
    })
    session_context = object({
      issuer_arn = string
    })
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
    vpc = object({
      id = string
    })
  })
}
