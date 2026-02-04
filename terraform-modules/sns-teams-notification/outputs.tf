output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.this.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.this.name
}

output "api_destination_arn" {
  description = "ARN of the EventBridge API destination"
  value       = aws_cloudwatch_event_api_destination.teams.arn
}

output "pipe_arn" {
  description = "ARN of the EventBridge Pipe"
  value       = aws_pipes_pipe.sns_to_teams.arn
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue used as pipe source"
  value       = aws_sqs_queue.pipe_source.arn
}
