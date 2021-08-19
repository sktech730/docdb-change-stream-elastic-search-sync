/*
aws_cloud_watch_event rule is same event bridge rule.
the code below will create schedule event rule,
 which will invoke specified target every 5 minute
*/

resource "aws_cloudwatch_event_rule" "sample_event_rule" {
  name = "sample_event_rule_to_trigger_cgange_stream"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "sample_event_target" {
  arn = "${aws_lambda_function.process_change_stream.arn}"
  rule = aws_cloudwatch_event_rule.sample_event_rule.name
  target_id = "trigger_change_stream_lambda"
}

/*
permission to invoke lambda by event rule
*/
resource "aws_lambda_permission" "process_change_stream_invoke_permission" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_change_stream.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.sample_event_rule.arn
}