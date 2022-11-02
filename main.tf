################################################################################
#                RUN THIS USING MANAGEMENT ACCOUNT CREDENTIALS                 #
################################################################################
# Datasource to connect to the current organization
data "aws_organizations_organization" "org" {
  provider = aws.management
}

################################################################################
#                          AWS Config Configuration                            #
################################################################################
# First we configure AWS Config in the primary region of the administrator/aggregator account
module "config_aggregator_primary_region" {
  source = "./modules/config"

  providers = {
    aws.account    = aws.security-admin
    aws.management = aws.management
  }

  config_bucket_name      = local.config_bucket_name                   # Name for the bucket to create
  organization_id         = data.aws_organizations_organization.org.id # Used for creating the SNS Topic policy
  config_sns_topic_prefix = var.config_sns_topic_prefix                # Used for creating the IAM role policy
  is_aggregator           = true                                       # This is the aggregator account
  is_primary_region       = true                                       # This is the primary region
}

# Next, we configure AWS Config in any additional region of the administrator/aggregator account
module "config_aggregator_global" {
  source = "./modules/config"

  providers = {
    aws.account    = aws.security-admin-us-east-1
    aws.management = aws.management-us-east-1
  }

  config_bucket_name  = module.config_aggregator_primary_region.config_bucket_name  # The bucket created in the primary region of the aggregator
  organization_id     = data.aws_organizations_organization.org.id                  # Used for creating the SNS Topic policy
  config_iam_role_arn = module.config_aggregator_primary_region.config_iam_role_arn # IAM role ARN to use for the recorder
  is_aggregator       = true                                                        # This is the aggregator account
  is_primary_region   = false                                                       # This is a secondary region

  depends_on = [
    module.config_aggregator_primary_region
  ]
}

# Now we can configure AWS Config for any additional account and region
module "config_management_primary_region" {
  source = "./modules/config"

  providers = {
    aws.account    = aws.management
    aws.management = aws.management
  }

  config_bucket_name      = module.config_aggregator_primary_region.config_bucket_name   # The bucket created in the prep
  config_sns_topic_arn    = module.config_aggregator_primary_region.config_sns_topic_arn # Region-specific SNS topic to send notifications to
  config_sns_topic_prefix = var.config_sns_topic_prefix                                  # Used for creating the IAM role policy
  is_aggregator           = false                                                        # This is not the aggregator account
  is_primary_region       = true                                                         # This is the primary region for the account
}

module "config_management_global" {
  source = "./modules/config"

  providers = {
    aws.account    = aws.management-us-east-1
    aws.management = aws.management-us-east-1
  }

  config_iam_role_arn  = module.config_management_primary_region.config_iam_role_arn # IAM role is already created in the account preparation
  config_bucket_name   = module.config_aggregator_primary_region.config_bucket_name  # The bucket created in the prep
  config_sns_topic_arn = module.config_aggregator_global.config_sns_topic_arn        # Region-specific SNS topic to send notifications to
  is_aggregator        = false                                                       # This is not the aggregator account
}

################################################################################
#                    Security Hub Administrator Delegation                     #
################################################################################
# This must be done for each region, including the global region (us-east-1).
# Global region is also needed for global resources, such as IAM
module "securityhub_admin_primary_region" {
  source = "./modules/securityhub"

  providers = {
    aws.account    = aws.security-admin
    aws.admin      = aws.security-admin
    aws.management = aws.management
  }

  securityhub_security_standards = var.securityhub_security_standards
  is_aggregation_region          = true
  invite                         = false
  is_admin                       = true
  is_member                      = false
}

module "securityhub_admin_global" {
  source = "./modules/securityhub"

  providers = {
    aws.account    = aws.security-admin-us-east-1
    aws.admin      = aws.security-admin-us-east-1
    aws.management = aws.management-us-east-1
  }

  securityhub_security_standards = var.securityhub_security_standards
  invite                         = false
  is_admin                       = true
  is_member                      = false
  
  depends_on = [
    module.securityhub_admin_primary_region,
  ]
}

################################################################################
#                         Security Hub Member Accounts                         #
################################################################################
# This must be done for each region, including the global region (us-east-1).
# Global region is also needed for global resources, such as IAM
module "securityhub_management_primary_region" {
  source = "./modules/securityhub"

  providers = {
    aws.account    = aws.management
    aws.admin      = aws.security-admin
    aws.management = aws.management
  }

  securityhub_security_standards = var.securityhub_security_standards
  invite                         = false
  is_admin                       = false
  is_member                      = true

  depends_on = [
    module.securityhub_admin_primary_region,
    module.securityhub_admin_global,
  ]
}

module "securityhub_management_global" {
  source = "./modules/securityhub"

  providers = {
    aws.account    = aws.management-us-east-1
    aws.admin      = aws.security-admin-us-east-1
    aws.management = aws.management-us-east-1
  }

  securityhub_security_standards = var.securityhub_security_standards
  invite                         = false
  is_admin                       = false
  is_member                      = true

  depends_on = [
    module.securityhub_admin_primary_region,
    module.securityhub_admin_global,
  ]
}
