terraform {
  required_version = ">=1.1.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.18.0"
    }
  }

  # backend "s3" {
  # }
}

provider "aws" {
  region = var.region

}
