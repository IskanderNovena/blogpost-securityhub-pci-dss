# AWS Config

Helps configure AWS Config.

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
| <a name="provider_aws.management"></a> [aws.management](#provider\_aws.management) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_config_configuration_aggregator.configuration_aggregator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_aggregator) | resource |
| [aws_config_configuration_recorder.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder) | resource |
| [aws_config_configuration_recorder_status.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_configuration_recorder_status) | resource |
| [aws_config_delivery_channel.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_delivery_channel) | resource |
| [aws_iam_role.config_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_organizations_delegated_administrator.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_delegated_administrator.config_multiaccount](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_s3_bucket.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.config_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_sns_topic.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config_bucket_name"></a> [config\_bucket\_name](#input\_config\_bucket\_name) | The bucket name - required by both aggregator and source accounts | `string` | n/a | yes |
| <a name="input_config_iam_role_arn"></a> [config\_iam\_role\_arn](#input\_config\_iam\_role\_arn) | ARN of the IAM role for Config. If `null` a role will be created. Defaults to `null`. | `string` | `null` | no |
| <a name="input_config_sns_topic_arn"></a> [config\_sns\_topic\_arn](#input\_config\_sns\_topic\_arn) | ARN of the SNS topic to publish events to. Required for source accounts. | `string` | `null` | no |
| <a name="input_config_sns_topic_prefix"></a> [config\_sns\_topic\_prefix](#input\_config\_sns\_topic\_prefix) | Prefix to use for creating an SNS topic. Required for the primary region of every account. | `string` | `null` | no |
| <a name="input_delivery_frequency"></a> [delivery\_frequency](#input\_delivery\_frequency) | The frequency with which AWS Config recurringly delivers configuration snapshots. May be one of One\_Hour, Three\_Hours, Six\_Hours, Twelve\_Hours, or TwentyFour\_Hours | `string` | `"TwentyFour_Hours"` | no |
| <a name="input_expiration"></a> [expiration](#input\_expiration) | The number of days to wait before expiring an object. | `number` | `1096` | no |
| <a name="input_is_aggregator"></a> [is\_aggregator](#input\_is\_aggregator) | Whether the account is to be an aggregator or not. | `bool` | `false` | no |
| <a name="input_is_primary_region"></a> [is\_primary\_region](#input\_is\_primary\_region) | Whether this is the primary region for the account. | `bool` | `false` | no |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Organization ID of the organization. Required for every aggregator region. | `string` | `null` | no |
| <a name="input_transition_to_glacier"></a> [transition\_to\_glacier](#input\_transition\_to\_glacier) | The number of days to wait before transitioning an object to Glacier. | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_config_bucket_name"></a> [config\_bucket\_name](#output\_config\_bucket\_name) | Name of the Config S3 bucket. |
| <a name="output_config_iam_role_arn"></a> [config\_iam\_role\_arn](#output\_config\_iam\_role\_arn) | IAM role ARN used for Config. |
| <a name="output_config_sns_topic_arn"></a> [config\_sns\_topic\_arn](#output\_config\_sns\_topic\_arn) | SNS topic ARN for Config. |
<!-- END_TF_DOCS -->