resource "aws_docdb_cluster" "sample" {
  cluster_identifier = var.docdb_cluster_sample
  engine = "docdb"
  master_username = var.master_docdb_user
  master_password = var.master_docdb_password
  db_subnet_group_name = aws_docdb_subnet_group.subnet_group.id
  vpc_security_group_ids = [
    aws_security_group.sample.id]
  skip_final_snapshot = true
  tags = local.common_tags
}

resource "aws_docdb_cluster_instance" "sample_instance" {
  count = 1
  identifier = var.sample_docdb_1
  cluster_identifier = aws_docdb_cluster.sample.id
  instance_class = "db.t3.medium"
  tags = local.common_tags
}

resource "aws_docdb_subnet_group" "subnet_group" {
  name = "main"
  subnet_ids = [
    var.private_subnet_1,
    var.private_subnet_2
  ]
  tags = local.common_tags
}