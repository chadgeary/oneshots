variable "install" {
  type = object({
    billing = optional(string, null)
    name    = string
  })
}
