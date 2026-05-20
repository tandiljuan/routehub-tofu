output "server_ipv4" {
  description = "List of servers' IPv4 addresses."
  value = {
    for name, server in hcloud_server.cluster :
      server.name =>
      coalesce(server.ipv4_address, try(one(server.network).ip, ""), "[EMPTY]")
  }
}
