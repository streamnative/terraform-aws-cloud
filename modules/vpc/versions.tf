terraform {
  required_version = ">=1.0.0"

  required_providers {
    aws = {
      version = ">= 3.64.2"
      source  = "hashicorp/aws"
    }
  }
}