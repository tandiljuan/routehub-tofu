terraform {
  required_version = ">= 1.10"

  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.62"
    }
  }
}

provider "hcloud" {
  token = var.htz_tkn
}
