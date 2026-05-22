resource "hcloud_volume" "main" {
  for_each = var.htz_vol_lst

  name = format(
    "%s-%s",
    hcloud_server.cluster[local.srv_lst_key[each.value.server]].name,
    each.value.name,
  )
  size = each.value.size
  format = each.value.format
  server_id = hcloud_server.cluster[local.srv_lst_key[each.value.server]].id
  automount = each.value.automount

  labels = merge(local.common_labels, { role = each.value.name })
  depends_on = [hcloud_server.cluster]
}
