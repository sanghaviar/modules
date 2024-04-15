data "aws_iam_role" "cross_account_role" {
  name = var.config["iam_role_name"]
}
resource "aws_iam_role_policy" "bucket_policy" {
  name = var.config["aws_iam_bucket_policy_name"]
  policy = jsonencode(jsondecode(file("config/${var.config["bucket_policy_filename"]}")))
  role   = data.aws_iam_role.cross_account_role.id
}