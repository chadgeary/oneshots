variable "aws_data" {
  type = object({
    default_tags = object({
      tags = object({
        Name = string
      })
    })
  })
}
