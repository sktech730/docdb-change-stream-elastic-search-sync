resource "aws_iam_role" "process-change-stream-lambda-role" {
  name = "process-change-stream-lambda-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "process-change-stream-lambda-policy" {
  name = "process-change-stream-lambda-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "secretsmanager:DescribeSecret",
              "secretsmanager:GetSecretValue"
           ],

          "Resource": "${aws_secretsmanager_secret.sample-documentdb.arn}"
      },
      {
        "Action": [
           "sqs:GetQueueAttributes",
           "sqs:GetQueueUrl",
           "sqs:SendMessage"

        ],
        "Resource": "${aws_sqs_queue.docdb_sync_es_queue.arn}",
        "Effect": "Allow"
      },
      {
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource": "*",
        "Effect": "Allow"
      }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "process-change-stream-lambda-policy-attachment" {
  name = "process-change-stream-lambda-policy-attachment"
  policy_arn = aws_iam_policy.process-change-stream-lambda-policy.arn
  roles = [
    aws_iam_role.process-change-stream-lambda-role.name]
}

resource "aws_iam_role" "update-elastisearch-lambda-role" {
  name = "update-elastisearch-lambda-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "update-elastisearch-lambda-policy" {
  name = "update-elastisearch-lambda"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
             "sqs:ReceiveMessage",
             "sqs:DeleteMessage",
             "sqs:GetQueueAttributes",
             "sqs:GetQueueUrl",
             "sqs:SendMessage",
             "sqs:DeleteMessageBatch"
        ],
        "Resource": "${aws_sqs_queue.docdb_sync_es_queue.arn}",
        "Effect": "Allow"
      },{
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource": "*",
        "Effect": "Allow"
      }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "update-elastisearch-lambda-policy-attachment" {
  name = "update-elastisearch-lambda-policy-attachment"
  policy_arn = aws_iam_policy.update-elastisearch-lambda-policy.arn
  roles = [
    aws_iam_role.update-elastisearch-lambda-role.name]
}