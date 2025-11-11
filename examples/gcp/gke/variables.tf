variable "install" {
  type = object({
    billing = optional(string, "My Billing Account")
    domain = optional(object({
      domainprovider = string
      domainname     = string
      token          = string
      }), {
      domainprovider = "duckdns"
      domainname     = "duckdns.org"
      token          = ""
    })
    gke = optional(object({
      disk_size_gb   = string
      machine_type   = string
      max_node_count = number
      min_node_count = number
      }), {
      disk_size_gb   = "10"
      machine_type   = "t2d-standard-1"
      max_node_count = 2
      min_node_count = 0
    })
    name = string
    network = optional(object({
      cidr = string
      }), {
      cidr = "10.100.0.0/19"
    })
    provider = optional(object({
      cloud        = string
      k8s          = string
      storageclass = string
      }), {
      cloud        = "gcp"
      k8s          = "gke"
      storageclass = "standard"
    })
    region = optional(string, "us-central1")
  })
}