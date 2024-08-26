variable "install" {
  type = object({
    name = string
    vpc = object({
      cidr  = string
      zones = number
    })
    duckdnstoken = string
  })
  default = {
    duckdnstoken = ""
    name         = "a-unique-name"
    vpc = {
      cidr  = "10.100.0.0/20"
      zones = 1
    }
  }
}
