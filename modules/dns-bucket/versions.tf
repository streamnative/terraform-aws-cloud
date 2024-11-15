terraform {
  required_version = ">=1.2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # NOTE! we required two different providers in this module
      # this is because we need to create a zone in the target
      # and then create the delegations in the source
      configuration_aliases = [aws.target, aws.source]
    }
  }
}

// NOTE! we need to create these so terraform validate works (even though it seems to be deperacted)
provider "aws" {
  alias = "target"
}

provider "aws" {
  alias = "source"
}
