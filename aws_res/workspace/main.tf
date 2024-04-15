
data "aws_iam_role" "this" {
  name = var.config["iam_role_name"]
}

#data "aws_s3_bucket" "metastore"{
#  bucket = "cueboxbucket119087"
#}

data "aws_s3_bucket" "metastore"{
  bucket = var.config["aws_s3_bucket_name"]
}

resource "aws_vpc" "vpc" {
  cidr_block = var.config["cidr_block"]
  tags = lookup(var.config,"vpc_tags",{} )
  enable_dns_hostnames = lookup(var.config,"enable_dns_hostnames",null)
  enable_dns_support = lookup(var.config,"enable_dns_support",null)
}

resource "aws_subnet" "private_subnet" {
  depends_on = [aws_vpc.vpc]
  vpc_id = aws_vpc.vpc.id
  count   = length(var.config["subnets"]["private_subnet_cidr_block"])
  cidr_block = var.config["subnets"]["private_subnet_cidr_block"][count.index]
  tags = can(var.config["private_subnet_tags"]) ? {
    for key, value in var.config["private_subnet_tags"] : key => can(value) && length(value) > 0 ? value[count.index] : null
  } : {}
}

resource "aws_subnet" "public_subnet" {
  depends_on = [aws_vpc.vpc]
  vpc_id = aws_vpc.vpc.id
  count   = length(var.config["subnets"]["public_subnet_cidr_block"])
  cidr_block = var.config["subnets"]["public_subnet_cidr_block"][count.index]
  tags = can(var.config["public_subnet_tags"]) ? {
    for key, value in var.config["public_subnet_tags"] : key => can(value) && length(value) > 0 ? value[count.index] : null
  } : {}
}

resource "aws_internet_gateway" "internet_gateway" {
  depends_on = [aws_vpc.vpc]
  vpc_id = aws_vpc.vpc.id
  tags = lookup(var.config,"internet_gateway_tags",{})
}
resource "aws_security_group" "security_group" {
  depends_on = [aws_vpc.vpc]
  name        = var.config["security_group_name"]
  vpc_id      = aws_vpc.vpc.id
  tags = lookup(var.config,"security_group_tags",{} )
}

resource "databricks_mws_networks" "mws_networks" {
  depends_on = [aws_vpc.vpc,aws_security_group.security_group]
  account_id   = var.ACCOUNT_ID
  network_name = var.config["network_name"]
  vpc_id = aws_vpc.vpc.id
  #  subnet_ids = aws_subnet.private_subnet.id
  subnet_ids = [for subnet in aws_subnet.private_subnet : subnet.id]
  security_group_ids = [aws_security_group.security_group.id]
}
resource "databricks_mws_credentials" "credentials" {
  credentials_name = var.config["mws_credential_name"]
  role_arn = data.aws_iam_role.this.arn
  account_id       = var.ACCOUNT_ID
}
resource "databricks_mws_storage_configurations" "storage_configurations" {
  account_id                 = var.ACCOUNT_ID
  bucket_name                = var.config["bucket_name"]
  storage_configuration_name = var.config["storage_configuration_name"]
}

resource "databricks_mws_workspaces" "workspace" {
  depends_on = [databricks_mws_credentials.credentials,databricks_mws_storage_configurations.storage_configurations,databricks_mws_networks.mws_networks]
  account_id     = var.ACCOUNT_ID
  aws_region     = var.region
  workspace_name = var.config["db_workspacename"]
  credentials_id = databricks_mws_credentials.credentials.credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.storage_configurations.storage_configuration_id
  network_id = databricks_mws_networks.mws_networks.network_id
}

resource "databricks_metastore" "DBmetastore" {
  name          = var.config["metastore_name"]
  storage_root  = "s3://${data.aws_s3_bucket.metastore.id}/metastore"
  region        = var.region
  force_destroy = lookup(var.config,"force_destroy",null)
}

resource "databricks_metastore_assignment" "metastore_assignment" {
  depends_on = [databricks_metastore.DBmetastore,databricks_mws_workspaces.workspace]
  metastore_id = databricks_metastore.DBmetastore.id
  workspace_id = databricks_mws_workspaces.workspace.workspace_id
}

resource "databricks_metastore_data_access" "data_access" {
  depends_on = [databricks_metastore.DBmetastore]
  metastore_id = databricks_metastore.DBmetastore.id
  name         = data.aws_iam_role.this.name
  aws_iam_role {
    role_arn = data.aws_iam_role.this.arn
  }
  is_default = var.config["is_default"]
}
