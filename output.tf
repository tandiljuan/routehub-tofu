output "server_ipv4" {
  description = "List of servers' IPv4 addresses."
  value = {
    for name, server in hcloud_server.cluster :
      server.name =>
      coalesce(server.ipv4_address, try(one(server.network).ip, ""), "[EMPTY]")
  }
}

output "volume_path" {
  description = "List of volumes' device paths."
  value = {
    for key, volume in hcloud_volume.main :
      volume.name =>
      coalesce(volume.linux_device, "[EMPTY]")
  }
}
