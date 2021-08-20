#======================
# Define Current Region
#======================

data "aws_region" "current" {}

#==========================
# Define Current Calller ID
#==========================

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "sample-documentdb" {
  name = "sample-documentdb"
  recovery_window_in_days = 0
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "sample-docdb_secret_version" {
  secret_id = aws_secretsmanager_secret.sample-documentdb.id
  secret_string = jsonencode(
  {
    "engine" : "mongo",
    "username": var.master_docdb_user
    "password": var.master_docdb_password,
    "host": aws_docdb_cluster.sample.endpoint
    "port": aws_docdb_cluster.sample.port
    "dbClusterIdentifier": aws_docdb_cluster.sample.cluster_identifier
    "uri": join("", [
      "mongodb://",
      aws_docdb_cluster.sample.endpoint,
      ":27017/?replicaSet=rs0&readPreference=secondaryPreferred"])
  }
  )
}

resource "aws_vpc_endpoint" "secret_manager_end_point" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    var.private_subnet_1,
    var.private_subnet_2
  ]
  security_group_ids = [
    aws_security_group.sample.id]
  tags = local.common_tags
}