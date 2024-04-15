data "databricks_aws_crossaccount_policy" "aws_crossaccount_policy" {
}
data "aws_iam_role" "cross_account_role" {
  name = var.config["iam_role_name"]
}
resource "aws_iam_role_policy" "role_policy" {
  name = var.config["aws_iam_role_policy_name"]
  policy = data.databricks_aws_crossaccount_policy.aws_crossaccount_policy.json
  role   = data.aws_iam_role.cross_account_role.id
}