terraform {
  required_version = ">= 0.15.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

resource "random_string" "name_suffix" {
  length  = 12
  special = false
  upper   = false
}

locals {
  name         = "${var.name_prefix}-${random_string.name_suffix.result}"
  default_tags = merge(var.default_tags, {})
}
