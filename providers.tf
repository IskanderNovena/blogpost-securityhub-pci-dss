# Provider for connecting to the root/management account in the chosen region
provider "aws" {
  region = var.region
}

# Provider for connecting to the root/management account in the chosen region
provider "aws" {
  region = var.region
  alias  = "management"
}

# Provider to connect to the management account for global services (us-east-1)
provider "aws" {
  region = "us-east-1"
  alias  = "management-us-east-1"
}

# Provider to connect to the admin account in the chosen region, using AssumeRole
provider "aws" {
  region = var.region
  alias  = "security-admin"

  assume_role {
    role_arn = local.assume_role_arn
  }
}

# Provider to connect to the admin account for global services (us-east-1), using AssumeRole
# https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_regions.html
provider "aws" {
  region = "us-east-1"
  alias  = "security-admin-us-east-1"

  assume_role {
    role_arn = local.assume_role_arn
  }
}
