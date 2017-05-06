# Discover Consul settings
module "consul" {
  source       = "github.com/nubisproject/nubis-terraform//consul?ref=v1.4.1"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
}

# Configure our Consul provider, module can't do it for us
provider "consul" {
  address    = "${module.consul.address}"
  scheme     = "${module.consul.scheme}"
  datacenter = "${module.consul.datacenter}"
}

# Publish our outputs into Consul for our application to consume
resource "consul_keys" "config" {
  # Just read this one
  key {
    name   = "active"
    path   = "${module.consul.config_prefix}/Active"
    delete = true
  }

  key {
    name   = "db_name"
    path   = "${module.consul.config_prefix}/DBname"
    value  = "${module.database.name}"
    delete = true
  }

  key {
    name   = "shadowdb_name"
    path   = "${module.consul.config_prefix}/ShadowDBname"
    value  = "${module.database.name}"
    delete = true
  }

  key {
    name   = "db_server"
    path   = "${module.consul.config_prefix}/DBserver"
    value  = "${module.database.address}"
    delete = true
  }

  key {
    name   = "shadowdb_server"
    path   = "${module.consul.config_prefix}/ShadowDBHost"
    value  = "${element(split(",",module.database.replicas),0)}"
    delete = true
  }

  key {
    name   = "db_username"
    path   = "${module.consul.config_prefix}/DBuser"
    value  = "${module.database.username}"
    delete = true
  }

  key {
    name   = "db_password"
    path   = "${module.consul.config_prefix}/DBpassword"
    value  = "${module.database.password}"
    delete = true
  }

  key {
    name   = "cache_port"
    path   = "${module.consul.config_prefix}/MemCachedPort"
    value  = "${module.cache.endpoint_port}"
    delete = true
  }

  key {
    name   = "cache_endpoint"
    path   = "${module.consul.config_prefix}/MemCachedEndpoint"
    value  = "${module.cache.endpoint_host}"
    delete = true
  }

  key {
    name   = "attachments_bucket"
    path   = "${module.consul.config_prefix}/S3AttachmentsBucket"
    value  = "${module.attachments.name}"
    delete = true
  }

  key {
    name   = "data_bucket"
    path   = "${module.consul.config_prefix}/S3DataBucket"
    value  = "${module.data.name}"
    delete = true
  }

  key {
    name   = "smtp_user"
    path   = "${module.consul.config_prefix}/SMTP/SESUser"
    value  = "${module.mail.smtp_user}"
    delete = true
  }

  key {
    name   = "smtp_password"
    path   = "${module.consul.config_prefix}/SMTP/SESPassword"
    value  = "${module.mail.smtp_password}"
    delete = true
  }

  key {
    name   = "smtp_host"
    path   = "${module.consul.config_prefix}/SMTP/SESServer"
    value  = "${module.mail.smtp_host}"
    delete = true
  }

  key {
    name   = "canonical_server"
    path   = "${module.consul.config_prefix}/CanonicalServer"
    value  = "https://${module.dns.fqdn}/"
    delete = true
  }
}
