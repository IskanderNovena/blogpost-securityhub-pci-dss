locals {
  create_sns_topic = var.config_sns_topic_arn == null && var.is_aggregator

  config_recorder_name = "config"
  config_sns_topic_arn = var.is_aggregator ? aws_sns_topic.config[0].arn : var.config_sns_topic_arn

  sns_topic_name = var.config_sns_topic_prefix != null ? join("-", [
    var.config_sns_topic_prefix,
    data.aws_caller_identity.current.account_id,
    data.aws_region.current.id,
  ]) : ""
}
