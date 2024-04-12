locals {
  replica_present = can(var.config["replica"])
  asm_policy_json = can(var.config["asm_policy_filename"]) ? jsonencode(jsondecode(file("config/${var.config["asm_policy_filename"]}"))) : null
}
resource "aws_secretsmanager_secret" "secret_manager" {
  name                    = var.config["name"]
  kms_key_id              = lookup(var.config, "kms_key_id", null)
  recovery_window_in_days = lookup(var.config, "recovery_window_in_days", null)
  policy                 = local.asm_policy_json
  dynamic "replica" {
    for_each = local.replica_present ? var.config["replica"] : []
    content {
      region = lookup(var.config,"region",null )
    }
  }
  force_overwrite_replica_secret = lookup(var.config,"force_overwrite_replica_secret",null)
  tags = lookup(var.config,"tags",{})
}


