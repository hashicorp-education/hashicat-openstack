terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0"
    }
  }
}

provider "openstack" {
  auth_url    = "${var.openstack_url}/identity"
  user_name   = "admin"
  password    = var.openstack_password
  tenant_name = var.tenant_name
  region      = "RegionOne"
}