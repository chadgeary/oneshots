variable "aws_data" {
  type = object({
    availability_zones = object({
      names = list(string)
    })
    default_tags = object({
      tags = object({
        Name = string
      })
    })
  })
}

variable "install" {
  type = object({
    name = string
    vpc = object({
      cidr  = string
      zones = number
    })
  })
}
