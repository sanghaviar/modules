data "databricks_aws_assume_role_policy" "assume_role_policy" {
  external_id = var.ACCOUNT_ID
}

data "databricks_aws_crossaccount_policy" "aws_crossaccount_policy" {
}

#data "aws_s3_bucket_policy" "bucket_policy"{
#  bucket = "cueboxbucket119087"
#}

data "aws_s3_bucket_policy" "bucket_policy"{
  bucket = var.config["aws_s3_bucket"]
}

resource "aws_iam_role" "cross_account_role" {
  name = var.config["aws_iam_role_name"]
  assume_role_policy = data.databricks_aws_assume_role_policy.assume_role_policy.json
}

resource "aws_iam_role_policy" "role_policy" {
  depends_on = [aws_iam_role.cross_account_role]
  name = var.config["aws_iam_role_policy_name"]
  policy = data.databricks_aws_crossaccount_policy.aws_crossaccount_policy.json
  role   = aws_iam_role.cross_account_role.id

}
resource "aws_iam_role_policy" "bucket_policy" {
  depends_on = [aws_iam_role.cross_account_role]
  name = var.config["aws_iam_bucket_policy_name"]
  policy = jsonencode(jsondecode(file("config/${var.config["bucket_policy_filename"]}")))
  role   = aws_iam_role.cross_account_role.id
}



