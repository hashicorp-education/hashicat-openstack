variable "openstack_url" {}
variable "openstack_password" {}

variable "prefix" {
  description = "This prefix will be included in the name."
}

variable "tenant_name" {
  description = "The Name of the Tenant (Identity v2) or Project (Identity v3)"
  default     = "admin"
}

variable "placeholder" {
  description = "This placeholder will be used to create a api resource"
  default     = "hello"
}