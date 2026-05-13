# --------------------------------------
# Network
# --------------------------------------

resource "hcloud_network" "main" {
  name = "${var.htz_pfx}-net"
  ip_range = var.htz_net_cidr
  labels  = merge(local.common_labels, { role = "main" })
}

resource "hcloud_network_subnet" "private" {
  network_id = hcloud_network.main.id
  type = "cloud"
  network_zone = var.htz_net_zne
  ip_range = var.htz_net_prv_cidr
}

# --------------------------------------
# Firewall
# --------------------------------------

resource "hcloud_firewall" "icmp" {
  name = "${var.htz_pfx}-icmp"
  rule {
    direction = "in"
    protocol = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  labels = merge(local.common_labels, { role = "icmp" })
}

resource "hcloud_firewall" "ssh" {
  name = "${var.htz_pfx}-ssh"
  rule {
    direction = "in"
    protocol = "tcp"
    port = "22"
    source_ips = var.htz_ssh_src
  }
  labels = merge(local.common_labels, { role = "ssh" })
}
