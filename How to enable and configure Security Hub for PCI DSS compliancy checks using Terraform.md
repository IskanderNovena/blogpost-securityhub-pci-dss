# How to enable and configure Security Hub for PCI DSS compliancy checks using Terraform

For companies that deal with payment card holder's data (CHD) and sensitive authentication data (SAD), obtaining PCI DSS compliancy is vital. It provides a set of standards and controls which help to prevent unauthorised access and data-loss. Often, adherence to these standards is a requirement for obtaining licenses that have to do with financial services, such as banking.

Excerpt from [PCI DSS v3.2.1 on AWS](https://d1.awsstatic.com/whitepapers/compliance/pci-dss-compliance-on-aws.pdf):

> The purpose of the PCI DSS is to protect cardholder data (CHD) and sensitive authentication data (SAD) from unauthorized access and loss. Cardholder data consists of the Primary Account Number (PAN), cardholder name, expiration date, and service code. Sensitive authentication data (SAD) includes the full track data (magnetic-stripe data or equivalent on a chip), CAV2/CVC2/CVV2/CID, and PINs/PIN blocks.

You can check if an AWS service is PCI compliant on the [`AWS Services in Scope by Compliance Program - PCI DSS` page](https://aws.amazon.com/compliance/services-in-scope/PCI/). Also, AWS publishes assessment reports of their certifications and attestation in [AWS Artifact](https://aws.amazon.com/artifact/), including the report for PCI DSS.

Aside from AWS being responsible for the compliancy of their infrastructure and services (security 'of' the cloud), the customer is responsible for the compliancy of the components used and the data processed (security 'in' the cloud), as per the [AWS Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/).

<img alt="AWS Shared Responsibility Model" style="width: 80%; margin: auto; align: center; display: block;" src="https://d1.awsstatic.com/security-center/Shared_Responsibility_Model_V2.59d1eccec334b366627e9295b304202faf7b899b.jpg" />

**Table of contents**

- [AWS services](#aws-services)
  - [Organisation settings](#organisation-settings)
  - [Setting up AWS Config](#setting-up-aws-config)
    - [Aggregation (delegated admin) account](#aggregation-delegated-admin-account)
    - [Additional accounts](#additional-accounts)
  - [Setting up AWS Security Hub](#setting-up-aws-security-hub)
    - [Admin account](#admin-account)
    - [Additional accounts](#additional-accounts-1)
  - [Executing the code](#executing-the-code)
- [Conclusion](#conclusion)

## AWS services

AWS provides tools to help us, the customer, prepare for our PCI DSS v3.2.1 assessment.

[AWS Security Hub](https://aws.amazon.com/security-hub/) is a cloud security posture management service, that performs security best practice checks, aggregates alerts, end enables automated remediation. This service provides a PCI DSS compliance package, that checks a set of controls related to PCI DSS requirements, to give an overview of your readiness for an assessment.  

In order to be able to check all controls, AWS Config needs to be [configured for Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-pci-config-resources.html) to be able to perform the PCI DSS checks.

I've written two modules, one for [Security Hub](https://github.com/IskanderNovena/blogpost-securityhub-pci-dss/blob/main/modules/securityhub/README.md) and one for [Config](https://github.com/IskanderNovena/blogpost-securityhub-pci-dss/blob/main/modules/config/README.md), to assist in configuring these services using Terraform, which are included in [this sample repository](https://github.com/IskanderNovena/blogpost-securityhub-pci-dss).

### Organisation settings

In AWS Organizations, AWS Config and Security Hub [must have been enabled for delegation](https://docs.aws.amazon.com/organizations/latest/userguide/services-that-can-integrate-config.html). This can be done using the [AWS console](https://us-east-1.console.aws.amazon.com/organizations/v2/home/services), or using AWS CLI:

```bash
aws organizations enable-aws-service-access --service-principal config.amazonaws.com
aws organizations enable-aws-service-access --service-principal config-multiaccountsetup.amazonaws.com
aws organizations enable-aws-service-access --service-principal securityhub.amazonaws.com
```

This can also be done [using Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization#enabled_policy_types), when creating the organisation. For example:

```hcl
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "securityhub.amazonaws.com",
    # any additional services to enable
  ]
  enabled_policy_types = [
    "BACKUP_POLICY",
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
  feature_set = "ALL"
}
```

### Setting up AWS Config

To configure AWS Config, we have to set it up in every accounts _**and**_ in every region we want to enable it. Also, setting up an aggregator helps to get an overview of all accounts and regions in a single place.

#### Aggregation (delegated admin) account

In [the example code](https://github.com/IskanderNovena/blogpost-securityhub-pci-dss/blob/main/main.tf), we first set up AWS Config in the account that will do the aggregation, in the primary region.

We pass providers for the account we are setting up (`aws.account`) and the management account (`aws.management`). The last one is needed to be able to delegate admin to the account.  

```hcl
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
```

This sets admin delegation to the account used in the `aws.account` provider in that specific region, and creates the following:

- An S3 bucket, which we use throughout the configuration
- an IAM role for the account
- A region-specific SNS Topic and corresponding policy
- An aggregator
- A recorder with delivery channel settings

For a secondary region, we need to set the admin delegation again, as well as create a region-specific SNS Topic.

```hcl
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
```

By setting `is_primary_region` to `false`, the following resources will not be created:

- S3 bucket (we only need one)
- IAM role (IAM is global)
- Aggregator (we only need one)

For the delivery channel, we set the S3 bucket to the one created in the aggregator primary region.

#### Additional accounts

For additional accounts, we have to configure Config as well, per region.

> **NOTE: Every account and every used region in the organisation have to be configured**

Since we cannot make a provider optional, we still have to pass a provider for the management account (`aws.management`).

```hcl
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
```

In the primary region of every account (`is_primary_region` set to `true`) we create an IAM role.

We refer to the S3 bucket created in the primary region in the aggregator account, as well as the region-specific SNS Topics in the aggregator account for the delivery channel of the recorder for every region in the account.

### Setting up AWS Security Hub

For setting up Security Hub, we need to take a similar approach, where we first configure the account that will be the delegated admin, per region, and then set up additional accounts that already existed at the time of enabling Security Hub. In the example module, the organisation will be configured to auto-enable Security Hub for new accounts.  

#### Admin account

In the example code, we first set up Security Hub in the account that will be the delegated admin, in the primary region, and again for every additional region.

We pass providers for:
- The account we are setting up (`aws.account`, used for configuring the account)
- The delegated admin account (`aws.admin`, used for inviting the account to Security Hub)
- The management account (`aws.management`, used for delegating admin and getting info about the account from AWS Organizations).   

```hcl
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
```

The `depends_on` is used to ensure the admin delegation has been completed in the primary region, before we start delegation in the additional region.

#### Additional accounts

Accounts that already existed when enabling and configuring Security Hub have to be configures in the Security Hub deployment.  

For example, adding the management account to Security Hub:

```hcl
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
```

In the definitions for the additional accounts, the `depends_on` attribute is used to ensure the admin account is set up first. Otherwise we might get errors during the step that invites the account to Security Hub.  

### Executing the code

Once the accounts and regions are added to the code, we can run `terraform plan` to see what actions will be taken:

```bash
> terraform plan

# ...

module.config_management_primary_region.data.aws_region.current: Reading...
module.config_management_primary_region.data.aws_caller_identity.current: Reading...
module.securityhub_admin_primary_region.data.aws_organizations_organization.org: Reading...
data.aws_organizations_organization.org: Reading...
module.config_management_primary_region.data.aws_region.current: Read complete after 0s [........]
module.config_management_primary_region.data.aws_caller_identity.current: Read complete after 1s [........]
module.securityhub_admin_primary_region.data.aws_caller_identity.account: Reading...
module.securityhub_admin_primary_region.data.aws_region.account: Reading...
module.config_aggregator_primary_region.data.aws_region.current: Reading...
module.securityhub_admin_primary_region.data.aws_caller_identity.admin: Reading...
module.config_aggregator_primary_region.data.aws_region.current: Read complete after 0s [........]
module.securityhub_admin_primary_region.data.aws_region.account: Read complete after 0s [........]
module.config_aggregator_primary_region.data.aws_caller_identity.current: Reading...
module.securityhub_admin_primary_region.data.aws_caller_identity.admin: Read complete after 0s [........]
module.securityhub_admin_primary_region.data.aws_caller_identity.account: Read complete after 0s [........]
module.config_aggregator_primary_region.data.aws_caller_identity.current: Read complete after 0s [........]
module.securityhub_admin_global.data.aws_organizations_organization.org: Reading...
module.config_management_global.data.aws_caller_identity.current: Reading...
module.config_management_global.data.aws_region.current: Reading...
module.config_management_global.data.aws_region.current: Read complete after 0s [........]
data.aws_organizations_organization.org: Read complete after 2s [........]
module.securityhub_admin_primary_region.data.aws_organizations_organization.org: Read complete after 2s [........]
module.config_management_global.data.aws_caller_identity.current: Read complete after 0s [........]
module.securityhub_admin_global.data.aws_caller_identity.account: Reading...
module.securityhub_admin_global.data.aws_caller_identity.admin: Reading...
module.securityhub_admin_global.data.aws_region.account: Reading...
module.securityhub_admin_global.data.aws_region.account: Read complete after 0s [........]
module.securityhub_admin_global.data.aws_caller_identity.account: Read complete after 1s [........]
module.securityhub_admin_global.data.aws_caller_identity.admin: Read complete after 1s [........]
module.securityhub_admin_global.data.aws_organizations_organization.org: Read complete after 2s [........]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

    # ...

Plan: 50 to add, 0 to change, 0 to destroy.
```

Once we apply the configuration, after about 24 hours, we can see the score per security standard, and the findings which need to be addressed.

<img alt="Sample PCI DSS score" style="width: 100%x; margin: auto; align: center; display: block;" src="https://d2908q01vomqb2.cloudfront.net/22d200f8670dbdb3e253a90eee5098477c95c23d/2020/02/14/PCI-DSS-Launch-For-Social-1260x630.jpg" />

## Conclusion

AWS Config and AWS Security Hub can play a big part in keeping your environment secure, and helping you to prepare for your PCI DSS assessment.  

One thing to be aware of, is that both services have to be set up for every region you do business in. To limit the regions, you can use a [Service Control Policy](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples_general.html#example-scp-deny-region) to limit the regions you can deploy to, while taking global services into account.
