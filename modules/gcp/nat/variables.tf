variable "install" {
  type = object({
    name = string
    network = object({
      cidr = string
    })
    region = string
  })
}

variable "gcp" {
  type = object({
    google_compute_image = map(object({
      id = string
    }))
    google_compute_zones = object({
      names = list(string)
    })
  })
}