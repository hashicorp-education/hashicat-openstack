variable "openstack_url" {}
variable "openstack_password" {}

variable "prefix" {
  description = "This prefix will be included in the name."
  default     = "gs"
}

variable "tenant_name" {
  description = "The Name of the Tenant (Identity v2) or Project (Identity v3)"
  default     = "admin"
}