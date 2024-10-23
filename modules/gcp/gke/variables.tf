variable "install" {
  type = object({
    gke = object({
      disk_size_gb   = string
      machine_type   = string
      max_node_count = number
      min_node_count = number
    })
    name = string
    network = object({
      cidr = string
    })
    region = string
  })
}

variable "gcp" {
  type = object({
    google_compute_zones = object({
      names = list(string)
    })
  })
}
