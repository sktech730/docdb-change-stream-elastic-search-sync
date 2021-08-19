/*
This service linked role needs to created only if the AWS account is not created it yet.
if your AWS account already have this role created this below code to create role
again will result into error. hence before creating this role please check your account
*/

resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

/*
Data source of Polciy, giving permission elastic search service
to publish logs to cloudwatcg log groups
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
a resource aws_cloudwatch_log_resource_policy gives permission to elastic
to publish logs to cloudwatcg log groups
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
    var.private-subnet-1,
    var.private-subnet-2
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