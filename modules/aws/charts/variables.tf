variable "aws" {
  type = object({
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
  })
}

variable "cluster" {
  type = object({
    idp = object({
      arn = string
      url = string
    })
  })
}

variable "install" {
  type = object({
    name = string
  })
}
