# --------------------------------------
# Network
# --------------------------------------

resource "hcloud_network" "main" {
  name = "${var.htz_pfx}-net"
  ip_range = var.htz_net_cidr
  labels = merge(local.common_labels, { role = "main" })
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

resource "hcloud_firewall" "dynamic" {
  for_each = var.htz_fwl_lst

  name = "${var.htz_pfx}-${each.value.name}"

  dynamic "rule" {
    for_each = each.value.rule

    content {
      direction = rule.value.direction
      protocol = rule.value.protocol
      port = rule.value.port
      source_ips = coalesce(rule.value.source, [])
      destination_ips = coalesce(rule.value.destination, [])
    }
  }

  dynamic "apply_to" {
    for_each = (
      can(keys(each.value.to_label))
      ? [for k, v in each.value.to_label: "${k}=${v}"]
      : try(compact(each.value.to_label), split(",", each.value.to_label), [])
    )
    iterator = label

    content {
      label_selector = label.value
    }
  }

  labels = merge(local.common_labels, { role = "dynamic" })
}

# --------------------------------------
# Load Balancer
# --------------------------------------

resource "hcloud_load_balancer" "main" {
  name = "${var.htz_pfx}-lb"
  load_balancer_type = var.htz_lb.type
  location = var.htz_loc

  labels = merge(local.common_labels, { role = "main" })

  lifecycle {
    enabled = var.htz_lb != null
  }
}
