variable "install" {
  type = object({
    name = string
    vpc = object({
      cidr  = string
      zones = number
    })
  })
  default = {
    name = "oneshots-k3s"
    vpc = {
      cidr  = "10.100.0.0/20"
      zones = 1
    }
  }
}
