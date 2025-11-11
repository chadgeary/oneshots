variable "install" {
  type = object({
    app    = string
    domain = string
    name   = string
    network = optional(object({
      cidr = string
      }), {
      cidr = "10.100.0.0/20"
    })
    playbook = string
  })
}
