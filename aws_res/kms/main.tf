data "aws_iam_role" "role" {
  name = "cuebox_roleeeeee"
}

resource "aws_kms_key" "kms_key" {
  key_usage = lookup(var.config,"key_usage",null)
  customer_master_key_spec = lookup(var.config,"customer_master_key_spec",null)
  bypass_policy_lockout_safety_check = lookup(var.config,"bypass_policy_lockout_safety_check",null )
  deletion_window_in_days = lookup(var.config,"deletion_window_in_days",null)
  is_enabled = lookup(var.config,"is_enabled",null )
}

resource "aws_kms_alias" "kms_name" {
  depends_on = [aws_kms_key.kms_key]
  name = var.config["description_name"]
  target_key_id = aws_kms_key.kms_key.key_id
}

resource "aws_kms_key_policy" "key_policy" {
  depends_on = [aws_kms_key.kms_key]
  key_id = aws_kms_key.kms_key.id
  policy = jsonencode(jsondecode(file("config/${var.config["kms_policy_filename"]}")))
}

