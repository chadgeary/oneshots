variable "install" {
  type = object({
    billing = optional(string, "My Billing Account")
    name    = string
    network = optional(object({
      cidr = string
      }), {
      cidr = "10.100.0.0/19"
    })
    region = optional(string, "us-central1")
  })
}