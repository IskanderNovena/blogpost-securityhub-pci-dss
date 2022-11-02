# Get the current region
data "aws_region" "account" {
  provider = aws.account
}

# Get the account identity
data "aws_caller_identity" "account" {
  provider = aws.account
}

# Get the admin identity
data "aws_caller_identity" "admin" {
  provider = aws.admin
}

# Get the current organization
data "aws_organizations_organization" "org" {
  provider = aws.management
}

# Enable SecurityHub on the account
resource "aws_securityhub_account" "account" {
  provider = aws.account
}

# Enable the security standards for the account
resource "aws_securityhub_standards_subscription" "account" {
  provider = aws.account

  for_each      = toset(var.securityhub_security_standards)
  standards_arn = lookup(local.securityhub_security_standards, each.key, null)

  depends_on = [
    aws_securityhub_account.account
  ]
}

# Delegate the admin role through the management account
resource "aws_securityhub_organization_admin_account" "admin" {
  count            = var.is_admin ? 1 : 0
  provider         = aws.management
  admin_account_id = data.aws_caller_identity.admin.id

  depends_on = [
    aws_securityhub_account.account
  ]
}

# Create the organization configuration
resource "aws_securityhub_organization_configuration" "admin" {
  count       = var.is_admin ? 1 : 0
  provider    = aws.account
  auto_enable = true

  depends_on = [
    aws_securityhub_organization_admin_account.admin
  ]
}

# Create the aggregator in the primary region
resource "aws_securityhub_finding_aggregator" "admin" {
  count        = var.is_admin && var.is_aggregation_region ? 1 : 0
  provider     = aws.account
  linking_mode = "ALL_REGIONS"

  depends_on = [aws_securityhub_account.account]
}

# Create the member-association and invite the member through the admin account
resource "aws_securityhub_member" "member" {
  count      = var.is_member ? 1 : 0
  provider   = aws.admin
  account_id = local.account.id
  email      = local.account.email
  invite     = var.invite

  depends_on = [
    aws_securityhub_account.account
  ]

  lifecycle {
    ignore_changes = [
      email,
      invite
    ]
  }
}

resource "aws_securityhub_product_subscription" "integration" {
  provider    = aws.account
  for_each    = toset(var.securityhub_integrations)
  depends_on  = [aws_securityhub_account.account]
  product_arn = lookup(local.available_securityhub_integrations, each.key, null)
}

# Accept the invite, using a provider with credentials for the member account.
# It looks like this is not needed when inviting accounts that are part of the same organization
# When running this, we get the error that no invite could be found. 
# Not having this resource doesn't seem to affect 'destroying' the configuration and doesn't result in errors.
resource "aws_securityhub_invite_accepter" "member" {
  count      = var.is_member == false && var.invite == true ? 1 : 0
  provider   = aws.account
  depends_on = [aws_securityhub_account.account]
  master_id  = one(aws_securityhub_member.member.*.master_id)
}
