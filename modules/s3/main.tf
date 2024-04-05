

resource "aws_s3_bucket" "root_storage_bucket" {
  bucket = var.config["aws_s3_bucket_name"]
  force_destroy = true
}

