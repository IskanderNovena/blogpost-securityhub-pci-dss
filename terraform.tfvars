region = "eu-central-1"
securityhub_security_standards = [
  "aws foundational security best practices", # is enabled by AWS by default
  "cis aws foundations",                      # is enabled by AWS by default
  "pci dss",
]
config_bucket_name_prefix = "config-bucket"
config_sns_topic_prefix   = "config-topic"
# security_account_id       = "012345678910"
