output "server_ipv4" {
  description = "Server IPv4"
  value = hcloud_server.main.ipv4_address
}
