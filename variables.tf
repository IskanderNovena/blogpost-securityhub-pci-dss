variable "region" {
  type        = string
  description = "AWS region in which to provision the Terraform resources."

  validation {
    condition     = contains(["eu-west-1", "eu-central-1"], var.region)
    error_message = "Variable 'region' must be one of: eu-west-1, eu-central-1."
  }
}

variable "organizations_role_name" {
  type        = string
  description = "The default AWS Organizations Role that is deployed in all AWS Accounts."
  default     = "OrganizationAccountAccessRole"
}

variable "security_account_id" {
  description = "Account ID to delegate admin to."
  type        = string
}

variable "sandbox_account_id" {
  description = "Account ID to the sandbox-account to add as member"
  type        = string
}

# AWS Config related
variable "config_bucket_name_prefix" {
  type        = string
  description = "Prefix for the AWS Config bucket name."
}

variable "config_sns_topic_prefix" {
  type        = string
  description = "Prefix to use for creating an SNS topic."
}

# Security Hub related
variable "securityhub_security_standards" {
  description = "List of the security standards to enable."
  type        = list(string)
  default = [
    "aws foundational security best practices",
    "cis aws foundations",
  ]

  validation {
    condition = alltrue([
      for standard in var.securityhub_security_standards : contains(["aws foundational security best practices", "cis aws foundations", "pci dss"], standard)
    ])
    error_message = "Variable 'securityhub_security_standards' must be one of: 'aws foundational security best practices', 'cis aws foundations', 'pci dss'."
  }
}
