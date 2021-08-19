resource "aws_security_group" "sample" {
  name = "doc-db-security-group"
  description = "Allows access to docdb from lambda"
  vpc_id = var.vpc_id
  tags = local.common_tags
}

resource "aws_security_group_rule" "sg-rule-ingress-docdb-port" {
  type = "ingress"
  from_port = 27017
  to_port = 27017
  protocol = "tcp"
  description = "Allow DocDB access from lambda in sub-1 and sub-2"
  security_group_id = aws_security_group.sample.id
  source_security_group_id = aws_security_group.sample.id
}

resource "aws_security_group_rule" "egress" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]
  security_group_id = aws_security_group.sample.id
}

resource "aws_security_group_rule" "sg-rule-ingress-docdb-http" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  description = "Allow HTTPS access from secret manager to lambda"
  security_group_id = aws_security_group.sample.id
  source_security_group_id = aws_security_group.sample.id
}
