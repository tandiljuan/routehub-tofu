resource "hcloud_server" "main" {
  name = "${var.htz_pfx}-main"

  server_type = var.htz_srv_typ
  image = var.htz_srv_img
  location = var.htz_loc
  ssh_keys = [data.hcloud_ssh_key.main.id]
  firewall_ids = [
    hcloud_firewall.icmp.id,
    hcloud_firewall.ssh.id,
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  labels = merge(local.common_labels, { role = "main" })
}
