module "worker" {
  source       = "github.com/nubisproject/nubis-terraform//worker?ref=v1.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
  ami          = "${var.ami}"
  elb          = "${module.load_balancer.name}"
  purpose      = "webserver"

  instance_type = "${lookup(var.instance_types, var.environment)}"

  # CPU utilisation based autoscaling (with good defaults)
  scale_load_defaults = true
}

module "queue-worker" {
  source       = "github.com/nubisproject/nubis-terraform//worker?ref=v1.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
  ami          = "${var.ami}"
  purpose      = "queue-worker"

  instance_type = "${lookup(var.instance_types, var.environment)}"

  # CPU utilisation based autoscaling (with good defaults)
  scale_load_defaults = true
}

module "push-worker" {
  source       = "github.com/nubisproject/nubis-terraform//worker?ref=v1.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
  ami          = "${var.ami}"
  purpose      = "push-worker"

  instance_type = "${lookup(var.instance_types, var.environment)}"

  # CPU utilisation based autoscaling (with good defaults)
  scale_load_defaults = true
}

module "load_balancer" {
  source              = "github.com/nubisproject/nubis-terraform//load_balancer?ref=v1.3.0"
  region              = "${var.region}"
  environment         = "${var.environment}"
  account             = "${var.account}"
  service_name        = "${var.service_name}"
  health_check_target = "HTTP:80/robots.txt?no-ssl-rewrite&elb-health-check"
  #ssl_cert_name_prefix = "bugzilla"
}

module "database" {
  source                 = "github.com/nubisproject/nubis-terraform//database?ref=v1.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
  client_security_groups = "${module.worker.security_group}"
  replica_count          = 1
  multi_az               = true
  instance_class         = "${lookup(var.db_instance_class, var.environment)}"
  allocated_storage      = "${lookup(var.db_allocated_storage, var.environment)}"
}

module "dns" {
  source       = "github.com/nubisproject/nubis-terraform//dns?ref=v1.3.0"
  region       = "${var.region}"
  environment  = "${var.environment}"
  account      = "${var.account}"
  service_name = "${var.service_name}"
  target       = "${module.load_balancer.address}"
}

module "storage" {
  source                 = "github.com/nubisproject/nubis-terraform//storage?ref=v1.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
  storage_name           = "bugzilla"
  client_security_groups = "${module.worker.security_group}"
}

module "cache" {
  source                 = "github.com/nubisproject/nubis-terraform//cache?ref=v1.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
  client_security_groups = "${module.worker.security_group}"
}

module "mail" {
  source                 = "github.com/nubisproject/nubis-terraform//mail?ref=v1.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
}

module "data" {
  source                 = "github.com/nubisproject/nubis-terraform//bucket?ref=v1.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
  purpose                = "data"
  role                  = "${module.worker.role}"
}

module "attachments" {
  source                 = "github.com/nubisproject/nubis-terraform//bucket?ref=v1.3.0"
  region                 = "${var.region}"
  environment            = "${var.environment}"
  account                = "${var.account}"
  service_name           = "${var.service_name}"
  purpose                = "attachments"
  role                  = "${module.worker.role}"
}
