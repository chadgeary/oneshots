variable "install" {
  type = object({
    domain = object({
      domainprovider = string
      domainname     = string
      token          = string
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