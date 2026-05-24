resource "hcloud_server" "cluster" {
  for_each = var.htz_srv_lst

  name = format("%s-%s", var.htz_pfx, each.value.name)
  server_type = each.value.type
  image = each.value.image
  location = var.htz_loc
  ssh_keys = [data.hcloud_ssh_key.main.id]
  firewall_ids = [
    hcloud_firewall.ssh.id,
  ]

  network {
    network_id = hcloud_network.main.id
    ip = each.value.private_ip
  }

  public_net {
    ipv4_enabled = each.key == local.srv_lst_key[0] ? true : false
    ipv6_enabled = each.key == local.srv_lst_key[0] ? false : true
  }

  labels = merge(local.common_labels, { role = each.value.role }, coalesce(each.value.labels, {}))
  depends_on = [hcloud_network_subnet.private]
}
