variable "install" {
  type = object({
    name = string
    charts = object({
      duckdnstoken = optional(string, "")
    })
    k3s = optional(object({
      controlplane = object({
        instance_types = list(string)
        volume_size    = number
        volume_type    = string
      })
      worker = object({
        instance_types = list(string)
        max_size       = number
        min_size       = number
        volume_size    = number
        volume_type    = string
      })
      ingress_cidrs = list(string)
      }), {
      controlplane = {
        instance_types = ["t3.small", "t3a.small", "t2.small"]
        volume_size    = "3"
        volume_type    = "gp3"
      }
      worker = {
        instance_types = ["m6g.medium", "m7g.medium", "m8g.medium", "t4g.medium"]
        max_size       = 2
        min_size       = 1
        volume_size    = "8"
        volume_type    = "gp3"
      }
      ingress_cidrs = ["0.0.0.0/0"]
    })
    provider = optional(object({
      cloud        = string
      k8s          = string
      storageclass = string
      }), {
      cloud        = "aws"
      k8s          = "k3s"
      storageclass = "gp3"
    })
    network = optional(object({
      cidr = string
      }), {
      cidr = "10.100.0.0/20"
    })
  })
}
