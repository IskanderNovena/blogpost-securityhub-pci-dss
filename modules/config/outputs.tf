output "config_sns_topic_arn" {
  description = "SNS topic ARN for Config."
  value       = var.is_aggregator ? aws_sns_topic.config[0].arn : var.config_sns_topic_arn
}

output "config_iam_role_arn" {
  description = "IAM role ARN used for Config."
  value       = var.is_primary_region ? one(aws_iam_role.config_role.*.arn) : var.config_iam_role_arn
}

output "config_bucket_name" {
  description = "Name of the Config S3 bucket."
  value       = var.is_aggregator && var.is_primary_region ? one(aws_s3_bucket.config_bucket.*.id) : var.config_bucket_name
}
