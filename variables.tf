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

# --------------------------------------
# Data
# --------------------------------------

# Chosen SSH key
data "hcloud_ssh_key" "main" {
  name = var.htz_ssh
}
