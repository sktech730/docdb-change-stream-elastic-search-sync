resource "aws_sqs_queue" "docdb_sync_es_queue" {
  fifo_queue = true
  name = "docdb_sync_es_change_stream_queue.fifo"
  visibility_timeout_seconds = 300
}

resource "aws_vpc_endpoint" "sample_sqs_endpoint" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids = [
    var.private_subnet_1,
    var.private_subnet_2
  ]
  security_group_ids = [aws_security_group.sample.id]
  tags = local.common_tags
}