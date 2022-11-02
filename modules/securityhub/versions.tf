terraform {
  required_version = ">= 1.3.0, < 1.4.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0.0"
      configuration_aliases = [aws.management, aws.account, aws.admin]
    }
  }
}
