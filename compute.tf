resource "hcloud_server" "cluster" {
  for_each = var.htz_srv_lst

  name = format("%s-%s", var.htz_pfx, each.value.name)
  server_type = var.htz_srv_typ
  image = var.htz_srv_img
  location = var.htz_loc
  ssh_keys = [data.hcloud_ssh_key.main.id]
  firewall_ids = [
    hcloud_firewall.icmp.id,
    hcloud_firewall.ssh.id,
  ]

  network {
    network_id = hcloud_network.main.id
    ip = each.value.private_ip
  }

  public_net {
    ipv4_enabled = each.key == local.srv_lst_key[0] ? true : false
    ipv6_enabled = false
  }

  user_data = (
    each.key == local.srv_lst_key[0]
    ? templatefile("${path.module}/script/gateway.yaml", {
      private_subnet = var.htz_net_prv_cidr
    })
    : templatefile("${path.module}/script/private.yaml", {
      gateway_ip = local.net_prv_gtw_ip
    })
  )

  labels = merge(local.common_labels, { role = each.value.type })
  depends_on = [hcloud_network_subnet.private]
}
