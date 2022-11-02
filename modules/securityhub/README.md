# AWS Security Hub

Helps configure AWS Security Hub.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.account"></a> [aws.account](#provider\_aws.account) | >= 4.0.0 |
| <a name="provider_aws.admin"></a> [aws.admin](#provider\_aws.admin) | >= 4.0.0 |
| <a name="provider_aws.management"></a> [aws.management](#provider\_aws.management) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_securityhub_account.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_finding_aggregator.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_finding_aggregator) | resource |
| [aws_securityhub_invite_accepter.member](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_invite_accepter) | resource |
| [aws_securityhub_member.member](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_member) | resource |
| [aws_securityhub_organization_admin_account.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_securityhub_organization_configuration.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_configuration) | resource |
| [aws_securityhub_product_subscription.integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_product_subscription) | resource |
| [aws_securityhub_standards_subscription.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_standards_subscription) | resource |
| [aws_caller_identity.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_caller_identity.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |
| [aws_region.account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_invite"></a> [invite](#input\_invite) | Invite the account to Security Hub as a member. Defaults to 'false'. | `bool` | `false` | no |
| <a name="input_is_admin"></a> [is\_admin](#input\_is\_admin) | Account is the admin account. | `bool` | `false` | no |
| <a name="input_is_aggregation_region"></a> [is\_aggregation\_region](#input\_is\_aggregation\_region) | This is the aggregation region for Security Hub. Only required for admin account. | `bool` | `false` | no |
| <a name="input_is_member"></a> [is\_member](#input\_is\_member) | Account is a member account. | `bool` | `true` | no |
| <a name="input_securityhub_integrations"></a> [securityhub\_integrations](#input\_securityhub\_integrations) | List of Security Hub integrations to subscribe to. | `list(string)` | `[]` | no |
| <a name="input_securityhub_security_standards"></a> [securityhub\_security\_standards](#input\_securityhub\_security\_standards) | List of the security standards to enable. | `list(string)` | <pre>[<br>  "aws foundational security best practices",<br>  "cis aws foundations"<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->