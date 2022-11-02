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

variable "securityhub_integrations" {
  type        = list(string)
  description = "List of Security Hub integrations to subscribe to."
  default     = []
}

variable "is_aggregation_region" {
  type        = bool
  description = "This is the aggregation region for Security Hub. Only required for admin account."
  default     = false
}

variable "is_admin" {
  type        = bool
  description = "Account is the admin account."
  default     = false
}

variable "is_member" {
  type        = bool
  description = "Account is a member account."
  default     = true
}

variable "invite" {
  type        = bool
  description = "Invite the account to Security Hub as a member. Defaults to 'false'."
  default     = false
}
