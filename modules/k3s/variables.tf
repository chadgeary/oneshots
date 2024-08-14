variable "aws" {
  type = object({
    default_tags = object({
      tags = object({
        Name = string
      })
    })
    session_context = object({
      issuer_arn = string
    })
  })
}
