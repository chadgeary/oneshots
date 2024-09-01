variable "install" {
  type = object({
    name = string
    charts = object({
      duckdnstoken = string
    })
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
    vpc = object({
      cidr  = string
      zones = number
    })
  })
  default = {
    name = "a-unique-name"
    charts = {
      duckdnstoken = ""
    }
    k3s = {
      controlplane = {
        instance_types = ["t4g.small", "a1.medium"]
        volume_size    = "5"
      }
      worker = {
        instance_types = ["t4g.small", "a1.medium"]
        max_size       = 3
        min_size       = 2
        volume_size    = "5"
        volume_type    = "gp3"
      }
      ingress_cidrs = ["0.0.0.0/0"]
    }
    vpc = {
      cidr  = "10.100.0.0/20"
      zones = 1
    }
  }
}
