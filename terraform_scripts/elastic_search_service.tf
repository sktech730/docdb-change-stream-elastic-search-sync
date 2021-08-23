/*
Use the resource below to create service linked role only if your AWS account doesn't already have it.
Recreating this resource will result in error.
*/

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

/*
Data source for policy to grant Elasticsearch permission to publish logs to CloudWatch
*/
data "aws_iam_policy_document" "elasticsearch-log-publishing-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = ["arn:aws:logs:*"]

    principals {
      identifiers = ["es.amazonaws.com"]
      type        = "Service"
    }
  }
}

/*
CloudWatch log group policy to grant Elasticsearch permission to publish logs
*/
resource "aws_cloudwatch_log_resource_policy" "sample_elastic_search_log_resource_policy" {
  policy_document = data.aws_iam_policy_document.elasticsearch-log-publishing-policy.json
  policy_name = "sample_elastic_search_log_resource_policy"

}

resource "aws_cloudwatch_log_group" "sample_elastic_search_log_group" {
  retention_in_days = 30
  name = "sample_elastic_search_log_group"

}

resource "aws_elasticsearch_domain" "sample_elastic_domain" {
  depends_on = [aws_cloudwatch_log_resource_policy.sample_elastic_search_log_resource_policy]
  domain_name           = "sample-elastic-domain"
  elasticsearch_version = "7.9"


  cluster_config {
    instance_type          = "t2.medium.elasticsearch"
    instance_count         = 2
    zone_awareness_enabled = "true"

    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.sample_elastic_search_log_group.arn
    enabled                  = true
    log_type                 = "ES_APPLICATION_LOGS"
  }
  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.sample_elastic_search_log_group.arn
    enabled                  = true
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  vpc_options {
    subnet_ids = [
    var.private_subnet_1,
    var.private_subnet_2
  ]
    security_group_ids = [aws_security_group.sample.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = "10"
  }
  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/sample-elastic-domain/*"

        }
    ]
}
CONFIG

//   depends_on = [
//    aws_iam_service_linked_role.sample_elastic_search_slr
//  ]
  tags = local.common_tags
}
