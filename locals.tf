locals {
  # Determine the ARN for the assume role to the audit-account
  assume_role_arn = "arn:aws:iam::${var.security_account_id}:role/${var.organizations_role_name}"

  # Get the current member accounts, except for the account that is the assigned delegated admin for Security Hub
  # This way, we can enable Security Hub on the already existing accounts.
  securityhub_member_accounts = [for account in data.aws_organizations_organization.org.accounts : {
    account_id    = account.id
    account_email = account.email
  } if account.id != var.security_account_id]

  config_bucket_name = join("-", [var.config_bucket_name_prefix, var.security_account_id])
}
