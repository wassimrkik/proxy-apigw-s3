locals {
  aws_account_id  = data.aws_caller_identity.current.account_id
  aws_region_name = data.aws_region.current.name
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}
