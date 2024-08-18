variable "aws" {
  type = object({
    amis = map(object({
      id = string
    }))
    caller_identity = object({
      account_id = string
    })
    default_tags = object({
      tags = object({
        Name = string
      })
    })
    partition = object({
      id = string
    })
    region = object({
      name = string
    })
    session_context = object({
      issuer_arn = string
    })
  })
}

variable "nat" {
  type = object({
    eip = map(object({
      public_ip = string
    }))
    security_group = object({
      id = string
    })
  })
}

variable "vpc" {
  type = object({
    networks = object({
      private = string
    })
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
