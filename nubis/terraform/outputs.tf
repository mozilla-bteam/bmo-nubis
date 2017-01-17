output "address" {
  value = "https://${module.dns.fqdn}/"
}

output "active" {
  value = "${consul_keys.config.var.active}"
}

output "attachments_bucket" {
  value = "${consul_keys.config.var.attachments_bucket}"
}

output "data_bucket" {
  value = "${consul_keys.config.var.data_bucket}"
}
