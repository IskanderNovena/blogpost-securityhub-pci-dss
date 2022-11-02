# AWS Config needs to have been enabled and configured with some settings for Security Hub being able to accurately repots on PCI-DSS controls.
# Reference: https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-pci-config-resources.html
data "aws_region" "current" {
  provider = aws.account
}

data "aws_caller_identity" "current" {
  provider = aws.account
}
# Bucket
resource "aws_s3_bucket" "config_bucket" {
  count         = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider      = aws.account
  bucket        = var.config_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_acl" "config_bucket" {
  count    = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider = aws.account
  bucket   = one(aws_s3_bucket.config_bucket.*.id)
  acl      = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket" {
  count    = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider = aws.account
  bucket   = one(aws_s3_bucket.config_bucket.*.bucket)

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config_bucket" {
  count    = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider = aws.account
  bucket   = one(aws_s3_bucket.config_bucket.*.id)

  rule {
    id     = "log"
    status = "Enabled"

    transition {
      days          = var.transition_to_glacier
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config_bucket" {
  count    = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider = aws.account
  bucket   = one(aws_s3_bucket.config_bucket.*.id)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  count    = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider = aws.account
  bucket   = one(aws_s3_bucket.config_bucket.*.id)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetBucketAcl"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "config.amazonaws.com"
        }
        Resource = "arn:aws:s3:::${var.config_bucket_name}"
      },
      {
        Action = ["s3:ListBucket"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "config.amazonaws.com"
        }
        Resource = "arn:aws:s3:::${var.config_bucket_name}"
      },
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "config.amazonaws.com"
        }
        Resource = "arn:aws:s3:::${var.config_bucket_name}/AWSLogs/*"
        Condition = {
          "StringLike" = {
            "s3:x-amz-acl" = ["bucket-owner-full-control"]
          }
        }
      }
    ]
  })
}

# Delegate AWS Config administrator
resource "aws_organizations_delegated_administrator" "config" {
  count             = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider          = aws.management
  account_id        = data.aws_caller_identity.current.account_id
  service_principal = "config.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "config_multiaccount" {
  count             = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider          = aws.management
  account_id        = data.aws_caller_identity.current.account_id
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

resource "aws_config_configuration_aggregator" "configuration_aggregator" {
  count    = var.is_aggregator && var.is_primary_region ? 1 : 0
  provider = aws.account
  name     = "aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn = var.is_primary_region ? one(aws_iam_role.config_role.*.arn) : var.config_iam_role_arn # var.config_iam_role_arn
  }

  depends_on = [
    aws_organizations_delegated_administrator.config,
    aws_organizations_delegated_administrator.config_multiaccount,
  ]
}

# IAM Role
# Only create this when it's the first region of the account we deploy to.
resource "aws_iam_role" "config_role" {
  count    = var.is_primary_region ? 1 : 0
  provider = aws.account
  name     = "ConfigRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole",
    "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
  ]

  inline_policy {
    name = "config-bucket-access"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["s3:PutObject"]
          Effect   = "Allow"
          Resource = "arn:aws:s3:::${var.config_bucket_name}/AWSLogs/*"
          Condition = {
            "StringLike" = {
              "s3:x-amz-acl" = ["bucket-owner-full-control"]
            }
          }
        },
        {
          Action   = ["s3:GetBucketAcl"]
          Effect   = "Allow"
          Resource = ["arn:aws:s3:::${var.config_bucket_name}"]
        },
        {
          Action   = ["sns:Publish"]
          Effect   = "Allow"
          Resource = ["arn:aws:sns:::${var.config_sns_topic_prefix}*"]
        }
      ]
    })
  }
}


# SNS Topic
resource "aws_sns_topic" "config" {
  count    = var.is_aggregator ? 1 : 0
  provider = aws.account
  name     = local.sns_topic_name
}

# Alternate method of creating the policy
# Compared to using jsonencode, this show better error messages
# data "aws_iam_policy_document" "sns_topic_policy" {
#   count = var.is_aggregator ? 1 : 0

#   policy_id = "SNSTopicsPub"
#   statement {
#     effect = "Allow"
#     sid = "default_policy"
#     actions = [
#       "SNS:GetTopicAttributes",
#       "SNS:SetTopicAttributes",
#       "SNS:AddPermission",
#       "SNS:RemovePermission",
#       "SNS:DeleteTopic",
#       "SNS:Subscribe",
#       "SNS:ListSubscriptionsByTopic",
#       "SNS:Publish",
#     ]
#     resources = aws_sns_topic.config.*.arn
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceOwner"
#       values = [
#         data.aws_caller_identity.current.account_id
#       ]
#     }
#   }
#   statement {
#     effect = "Allow"
#     sid = "org-level-permission"
#     actions = [
#       "SNS:Publish",
#     ]
#     resources = aws_sns_topic.config.*.arn
#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "AWS:PrincipalOrgID"
#       values = [
#         var.organization_id
#       ]
#     }
#   }
# }

resource "aws_sns_topic_policy" "config" {
  count    = var.is_aggregator ? 1 : 0
  provider = aws.account
  arn      = join("", aws_sns_topic.config.*.arn)

  # policy = data.aws_iam_policy_document.sns_topic_policy[0].json
  policy = jsonencode({

    # Version = "2008-10-17"
    Version = "2012-10-17"
    Id      = "Custom_Policy"
    Statement = [
      {
        Sid    = "default-policy"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        },
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish",
        ],
        Resource = aws_sns_topic.config.*.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "org-level-permission"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "sns:Publish",
        ]
        Resource = aws_sns_topic.config.*.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.organization_id
          }
        }
      },
    ]
  })
}

# Recorder
resource "aws_config_configuration_recorder" "config" {
  provider = aws.account
  name     = local.config_recorder_name
  role_arn = var.is_primary_region ? one(aws_iam_role.config_role.*.arn) : var.config_iam_role_arn
  recording_group {
    # We can either include all resources, including future resources and global resources
    include_global_resource_types = var.is_primary_region
    all_supported                 = true

    # Or we can include only the required resources
    # Reference: https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-standards-pci-config-resources.html
    # all_supported = false
    # resource_types = [
    #   "AWS account",
    #   "AWS::IAM::Group",
    #   "AWS::IAM::Policy",
    #   "AWS::IAM::Role",
    #   "AWS::IAM::User",
    #   "AWS::AutoScaling::AutoScalingGroup",
    #   "AWS::CloudTrail::Trail",
    #   "AWS::CodeBuild::Project",
    #   "AWS::DMS::ReplicationInstance",
    #   "AWS::EC2::EIP",
    #   "AWS::EC2::Instance",
    #   "AWS::EC2::SecurityGroup",
    #   "AWS::EC2::Volume",
    #   "AWS::EC2::VPC",
    #   "AWS::ElasticLoadBalancingV2::LoadBalancer",
    #   "AWS::Elasticsearch::Domain",
    #   "AWS::IAM::Policy",
    #   "AWS::IAM::User",
    #   "AWS::KMS::Key",
    #   "AWS::Lambda::Function",
    #   "AWS::RDS::DBInstance",
    #   "AWS::RDS::DBSnapshot",
    #   "AWS::Redshift::Cluster",
    #   "AWS::S3::Bucket",
    #   "AWS::SageMaker::NotebookInstance",
    #   "AWS::SSM::AssociationCompliance",
    #   "AWS::SSM::PatchCompliance",
    # ]
  }
}

resource "aws_config_delivery_channel" "config" {
  provider       = aws.account
  name           = local.config_recorder_name
  s3_bucket_name = var.is_aggregator && var.is_primary_region ? one(aws_s3_bucket.config_bucket.*.id) : var.config_bucket_name
  snapshot_delivery_properties {
    delivery_frequency = var.delivery_frequency
  }
  sns_topic_arn = var.is_aggregator ? one(aws_sns_topic.config.*.arn) : var.config_sns_topic_arn
  depends_on    = [aws_config_configuration_recorder.config]
}

resource "aws_config_configuration_recorder_status" "config" {
  provider   = aws.account
  is_enabled = true
  name       = aws_config_configuration_recorder.config.name
  depends_on = [aws_config_delivery_channel.config]
}

# # Rules
# resource "aws_config_config_rule" "config_rules" {
#   for_each = var.config_rules
#   provider = aws.account
#   name     = each.key
#   source {
#     owner             = each.value.source.owner
#     source_identifier = each.value.source.source_identifier
#   }
#   scope {
#     compliance_resource_types = each.value.scope.compliance_resource_types
#   }
#   depends_on = [aws_config_configuration_recorder.config]
# }
