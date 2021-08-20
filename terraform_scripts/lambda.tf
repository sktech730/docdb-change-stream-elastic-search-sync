/*
terraform archive construct, which will zip the contents of specified
directory into specified output path
*/

data "archive_file" "process_change_stream" {

  type = "zip"
  output_file_mode = "0666"
  source_dir = "${path.module}/../src/process_change_stream/"
  output_path = "${path.module}/files/process_change_stream.zip"
}

/*
  A lambda function which will watch the amazon document Db change stream.
  Function will be invoked by event bridge, scheduled event rule every 5 minute.
  a lambda function will be deployed in the form of zipped file
  using archive construct of terraform
  Environment Variables passed to function:
    DOCUMENTDB_NAME: Name of Document DB Instance ina cluster to watch for change stream
    COLLECTION_NAME: Name collection to watch in Document DB database
    state: Name of collection in which checkpoint will be stored.
    DOCUMENTS_PER_INVOCATION: Number of documents from change stream to be collected in each invocation
    SYNC_TOKEN_FREQUENCY: Number of times the checkpoint token stored in a collection per invocation
    SQS_QUERY_URL: Fifo SQS queue URL
    SQS_ENDPOINT_URL: SQS queue endpoint url, as lambda function will be running in VPC, need endpoint to communicate with sqs
    SECRETS_MANAGER_ENDPOINT: Secret manager end point url,as lambda function will be running in VPC, need endpoint to communicate with secret manager
    DOCUMENTDB_SECRET: secret name in which document DB credentials are stored.

*/
resource "aws_lambda_function" "process_change_stream" {
  depends_on = [
    data.archive_file.process_change_stream]
  filename = data.archive_file.process_change_stream.output_path
  function_name = "process_change_stream"
  role = aws_iam_role.process-change-stream-lambda-role.arn
  handler = "process_change_stream.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.process_change_stream.output_path)
  layers = [aws_lambda_layer_version.pymongo_elasticsearch_lambda_layer.arn]
  timeout = 300
  runtime = "python3.8"
  vpc_config {
    subnet_ids = [
      var.private_subnet_1,
      var.private_subnet_2
    ]
    security_group_ids = [
      aws_security_group.sample.id]
  }

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
      DOCUMENTDB_NAME = aws_docdb_cluster_instance.sample_instance[0].identifier
      COLLECTION_NAME = "sample"
      state = "state"
      DOCUMENTS_PER_INVOCATION = "10"
      SYNC_TOKEN_FREQUENCY = "5"
      SQS_QUERY_URL = aws_sqs_queue.docdb_sync_es_queue.id
      SQS_ENDPOINT_URL = "https://sqs.${data.aws_region.current.name}.amazonaws.com"
      DOCUMENTDB_SECRET = aws_secretsmanager_secret.sample-documentdb.name

    }
  }
}

data "archive_file" "update_elasticsearch_service" {
  type = "zip"
  output_file_mode = "0666"
  source_dir = "${path.module}/../src/update_elasticsearch_service/"
  output_path = "${path.module}/files/update_elasticsearch_service.zip"
}

resource "aws_lambda_event_source_mapping" "update_elasticsearch_service_event_source" {
  event_source_arn = aws_sqs_queue.docdb_sync_es_queue.arn
  function_name = aws_lambda_function.update_elasticsearch_service.arn
  batch_size = 10
  enabled = true

}

/*
This lambda function will be backed by SQS Fifo queue, as shown in above event source mapping
Environment Variables Passed:
  ELASTICSEARCH_URI: elastic search service end point url to connect amazon elastic search service.
*/

resource "aws_lambda_function" "update_elasticsearch_service" {
  depends_on = [
    data.archive_file.update_elasticsearch_service]
  filename = data.archive_file.update_elasticsearch_service.output_path
  function_name = "update_elasticsearch_service"
  role = aws_iam_role.update-elastisearch-lambda-role.arn
  handler = "update_elasticsearch_service.lambda_handler"
  source_code_hash = filebase64sha256(data.archive_file.update_elasticsearch_service.output_path)

  layers = [aws_lambda_layer_version.pymongo_elasticsearch_lambda_layer.arn]
  timeout = 300
  runtime = "python3.8"
  vpc_config {
    subnet_ids = [
      var.private_subnet_1,
      var.private_subnet_2
    ]
    security_group_ids = [
      aws_security_group.sample.id]
  }
  environment {
    variables = {
      ELASTICSEARCH_URI: "https://${aws_elasticsearch_domain.sample_elastic_domain.endpoint}"
    }
  }
}

resource "null_resource" "pymongo_elasticsearch_lambda_layer_build" {
  triggers = {
    requirements = "${base64sha256(file("${path.module}/../src/requirements.txt"))}"
    build        = "${base64sha256(file("${path.module}/../src/build.sh"))}"
  }
  provisioner "local-exec" {
    command = "${path.module}/../src/build.sh"
  }
}

data "archive_file" "pymongo_elasticsearch_lambda_layer" {
  depends_on = [null_resource.pymongo_elasticsearch_lambda_layer_build]
  type = "zip"
  output_file_mode = "0666"
  source_dir = "${path.module}/../src/pymongo_elasticsearch_lambda_layer/"
  output_path = "${path.module}/files/pymongo_elasticsearch_lambda_layer.zip"
}

resource "aws_lambda_layer_version" "pymongo_elasticsearch_lambda_layer" {
  filename   = data.archive_file.pymongo_elasticsearch_lambda_layer.output_path
  layer_name = "pymongo_elasticsearch_lambda_layer"
  compatible_runtimes = ["python3.8"]
}
