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
