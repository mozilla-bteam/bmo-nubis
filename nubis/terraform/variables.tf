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
  }
}

variable "db_allocated_storage" {
  type = "map"

  default = {
    stage = "64"
    prod  = "128"
  }
}

variable "db_instance_class" {
  type = "map"

  default = {
    stage = "db.t2.medium"
    prod  = "db.r3.4xlarge"
  }
}
