resource "aws_s3_bucket" "this" {
  bucket        = "${var.aws.default_tags.tags["Name"]}-cluster"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this-s3.json
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "90day-snapshots"
    status = "Enabled"
    filter {
      prefix = "controlplane/snapshots/"
    }
    expiration {
      days = 90
    }
  }
  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = "https://${aws_s3_bucket.this.id}.s3.${var.aws.region.name}.amazonaws.com/controlplane/oidc"
  client_id_list  = [var.aws.default_tags.tags["Name"]]
  thumbprint_list = [chomp(lower(data.aws_s3_object.this["oidc/ca.thumbprint"].body))]
}
