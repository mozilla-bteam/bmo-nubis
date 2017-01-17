output "address" {
  value = "https://${module.dns.fqdn}/"
}

output "active" {
  value = "${consul_keys.config.var.active}"
}

output "attachments-bucket" {
  value = "${consul_keys.config.var.attachments_bucket}"
}

output "data-bucket" {
  value = "${consul_keys.config.var.data_bucket}"
}
