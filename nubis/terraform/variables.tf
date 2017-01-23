variable "account" {}

variable "region" {
  default = "us-west-2"
}

variable "environment" {
  default = "stage"
}

variable "service_name" {
  default = "bugzilla"
}

variable "ami" {}

variable "ssh_key_file" {
  default = ""
}

variable "ssh_key_name" {
  default = ""
}

variable "instance_types" {
  type = "map"

  default = {
    stage = "t2.medium"
    prod  = "m4.xlarge"
    any   = "t2.nano"
  }
}

variable "min_instances" {
  type = "map"

  default = {
    stage = 2
    prod  = 2
    any   = 2
  }
}

variable "max_instances" {
  type = "map"

  default = {
    stage = 4
    prod  = 8
    any   = 4
  }
}

variable "db_allocated_storage" {
  type = "map"

  default = {
    stage = "256"
    prod  = "256"
    any   = "64"
  }
}

variable "db_instance_class" {
  type = "map"

  default = {
    stage = "db.t2.medium"
    prod  = "db.r3.4xlarge"
    any   = "db.t2.small"
  }
}

variable "db_name" {
  type = "map"

  default = {
    stage = "bugzilla_allizom_org"
    prod  = "bugs"
    any   = "bugs"
  }
}
