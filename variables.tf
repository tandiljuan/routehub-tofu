# --------------------------------------
# Variables
# --------------------------------------

variable "htz_tkn" {
  description = "Hetzner Cloud API token"
  type = string
  sensitive = true
}

variable "htz_pjt" {
  description = "Project name"
  type = string
  default = "RouteHub"
}

variable "htz_pfx" {
  description = "Global project prefix"
  type = string
  default = "rh"
}

variable "htz_loc" {
  description = "Hetzner location name"
  type = string
  default = "hel1"
}

variable "htz_net_zne" {
  description = "Network Zone"
  type = string
  default = "eu-central"
}

variable "htz_net_cidr" {
  description = "Network IP range"
  type = string
  default = "10.0.0.0/16"
}

variable "htz_net_prv_cidr" {
  description = "Private subnet IP range"
  type = string
  default = "10.0.1.0/24"
}

variable "htz_ssh" {
  description = "SSH key name"
  type = string
}

variable "htz_ssh_src" {
  description = "List of allowed SSH source IPs"
  type = list(string)
  default = [
    "0.0.0.0/0",
    "::/0"
  ]
}

variable "htz_srv_typ" {
  description = "Hetzner server type"
  type = string
  default = "cx23"
}

variable "htz_srv_img" {
  description = "Hetzner server image"
  type = string
  default = "ubuntu-24.04"
}

variable "htz_srv_lst" {
  description = "Hetzner server list"
  type = map(object({
    name = string,
    type = string,
    private_ip = string,
  }))
  default = {
    01 = { name = "nat", type = "gateway", private_ip = "10.0.1.1" },
    02 = { name = "pvt", type = "private", private_ip = "10.0.1.2" },
  }
}

# --------------------------------------
# Data
# --------------------------------------

# Chosen SSH key
data "hcloud_ssh_key" "main" {
  name = var.htz_ssh
}

# --------------------------------------
# Locals
# --------------------------------------

locals {
  common_labels = {
    project = var.htz_pjt
    managed_by = "opentofu"
  }
  srv_lst_key = sort(keys(var.htz_srv_lst))
  # Gateway IP
  # @see https://docs.hetzner.com/networking/networks/faq/#how-do-i-setup-my-own-router
  net_prv_gtw_ip = cidrhost(var.htz_net_cidr, 1)
}
