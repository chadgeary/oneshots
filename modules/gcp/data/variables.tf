variable "install" {
  type = object({
    billing = optional(string, "")
    name    = string
    region  = string
  })
}