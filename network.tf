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

resource "hcloud_load_balancer_network" "private" {
  load_balancer_id = hcloud_load_balancer.main.id
  subnet_id = hcloud_network_subnet.private.id
  ip = var.htz_lb.private_ip

  lifecycle {
    enabled = hcloud_load_balancer.main != null
  }
}

resource "hcloud_load_balancer_service" "dynamic" {
  for_each = merge({}, try(var.htz_lb.services, null))

  load_balancer_id = hcloud_load_balancer.main.id
  protocol = each.value.protocol
  listen_port = each.value.from
  destination_port = each.value.to

  dynamic "http" {
    for_each = each.value.http != null ? [each.value.http] : []
    iterator = http

    content {
      sticky_sessions = http.value.sticky
      cookie_name = http.value.cookie
      cookie_lifetime = http.value.lifetime
      certificates = http.value.certs
      redirect_http = http.value.redirect
    }
  }

  dynamic "health_check" {
    for_each = each.value.check != null ? [each.value.check] : []
    iterator = check

    content {
      protocol = check.value.protocol
      port = check.value.port
      interval = check.value.interval
      timeout = check.value.timeout
      retries = check.value.retries

      dynamic "http" {
        for_each = check.value.http != null ? [check.value.http] : []
        iterator = http

        content {
          domain = http.value.domain
          path = http.value.path
          response = http.value.response
          status_codes = http.value.codes
        }
      }
    }
  }
}

resource "hcloud_load_balancer_target" "cluster" {
  for_each = var.htz_lb != null ? hcloud_server.cluster : {}

  type = "server"
  load_balancer_id = hcloud_load_balancer.main.id
  server_id = each.value.id
  use_private_ip = true
}
