variable "install" {
  type = object({
    charts = object({
      duckdnstoken = string
    })
    name = string
    provider = object({
      cloud        = string
      k8s          = string
      storageclass = string
    })
  })
}

variable "nat" {
  type = object({
    eip = object({
      public_ip = string
    })
  })
}