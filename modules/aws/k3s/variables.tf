variable "aws" {
  type = object({
    amis = map(object({
      id               = string
      root_device_name = string
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

variable "install" {
  type = object({
    k3s = object({
      controlplane = object({
        instance_types = list(string)
        volume_size    = number
      })
      worker = object({
        instance_types = list(string)
        max_size       = number
        min_size       = number
        volume_size    = number
        volume_type    = string
      })
      ingress_cidrs = list(string)
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
      availability_zone = string
      cidr_block        = string
      id                = string
    })))
    vpc = object({
      cidr_block = string
      id         = string
    })
  })
}