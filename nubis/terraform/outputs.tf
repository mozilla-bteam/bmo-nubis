output "address" {
  value = "https://${module.dns.fqdn}/"
}

output "active" {
  value = "${consul_keys.config.var.active}"
}
