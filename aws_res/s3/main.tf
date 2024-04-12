data "databricks_aws_bucket_policy" "this" {
  bucket = "cueboxbucket119087"
}

resource "aws_s3_bucket" "root_storage_bucket" {
  bucket = var.config["aws_s3_bucket_name"]
  force_destroy = true
}
resource "aws_s3_bucket_policy" "root_bucket_policy" {
  depends_on = [aws_s3_bucket.root_storage_bucket]
  bucket     = aws_s3_bucket.root_storage_bucket.id
  policy     = data.databricks_aws_bucket_policy.this.json
}


