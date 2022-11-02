variable "config_sns_topic_prefix" {
  type        = string
  nullable    = true
  description = "Prefix to use for creating an SNS topic. Required for the primary region of every account."
  default     = null
}

variable "config_sns_topic_arn" {
  type        = string
  nullable    = true
  description = "ARN of the SNS topic to publish events to. Required for source accounts."
  default     = null
}

variable "config_iam_role_arn" {
  type        = string
  description = "ARN of the IAM role for Config. If `null` a role will be created. Defaults to `null`."
  nullable    = true
  default     = null
}

variable "organization_id" {
  type        = string
  description = "Organization ID of the organization. Required for every aggregator region."
  nullable    = true
  default     = null
}

variable "delivery_frequency" {
  type        = string
  description = "The frequency with which AWS Config recurringly delivers configuration snapshots. May be one of One_Hour, Three_Hours, Six_Hours, Twelve_Hours, or TwentyFour_Hours"
  default     = "TwentyFour_Hours"

  validation {
    condition     = contains(["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"], var.delivery_frequency)
    error_message = "Variable 'delivery_frequency' must be one of: 'One_Hour', 'Three_Hours', 'Six_Hours', 'Twelve_Hours', or 'TwentyFour_Hours'."
  }
}

variable "is_aggregator" {
  type        = bool
  description = "Whether the account is to be an aggregator or not."
  default     = false
}

variable "is_primary_region" {
  type        = bool
  description = "Whether this is the primary region for the account."
  default     = false
}

variable "config_bucket_name" {
  type        = string
  description = "The bucket name - required by both aggregator and source accounts"
}

variable "expiration" {
  type        = number
  description = "The number of days to wait before expiring an object."
  default     = 1096
}

variable "transition_to_glacier" {
  type        = number
  description = "The number of days to wait before transitioning an object to Glacier."
  default     = 30
}
