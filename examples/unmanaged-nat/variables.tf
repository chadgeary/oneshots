variable "install" {
  type = object({
    name = string
    vpc = object({
      cidr  = string
      zones = number
    })
  })
  default = {
    name = "1shot2"
    vpc = {
      cidr  = "10.100.0.0/20"
      zones = 1
    }
  }
}
