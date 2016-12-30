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

variable "allocated_storage" {
  type = "map"

  default = {
    stage = "64"
    prod  = "128"
  }
}
