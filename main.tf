resource "openstack_images_image_v2" "centos" {
  name             = "CentOS7"
  image_source_url = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2003.qcow2.xz"
  container_format = "bare"
  disk_format      = "qcow2"

  properties = {
    key = "os"
  }
}

locals {
  images = yamldecode(file("${path.module}/images.yaml"))
}

resource "openstack_images_image_v2" "images" {
  for_each = local.images

  name             = each.key
  image_source_url = each.value.image_source_url
  container_format = each.value.container_format
  disk_format      = each.value.disk_format

  properties = each.value.properties
}

resource "openstack_compute_keypair_v2" "test-keypair" {
  name = "my-keypair"
}

resource "local_file" "ssh_private_key" {
  content         = openstack_compute_keypair_v2.test-keypair.private_key
  file_permission = "0600"
  filename        = "openstack_ssh_private"
}

data "openstack_networking_network_v2" "public_network" {
  name = "public"
}

data "openstack_networking_network_v2" "shared_network" {
  name = "shared"
}

data "openstack_networking_subnet_v2" "subnet_1" {
  name       = "shared-subnet"
  network_id = data.openstack_networking_network_v2.shared_network.id
}

# 라우터 생성
resource "openstack_networking_router_v2" "router_1" {
  name                = "my_router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.public_network.id
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = data.openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_networking_secgroup_v2" "secgroup_1" {
  name        = "secgroup_1"
  description = "a security group"
}

# Allow ICMP (ping)
resource "openstack_networking_secgroup_rule_v2" "allow_ping" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

resource "openstack_networking_secgroup_rule_v2" "web" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup_1.id
}

resource "openstack_compute_instance_v2" "instance01" {
  name     = "instance01"
  image_id = openstack_images_image_v2.images["Ubuntu-24.04-noble"].id
  #image_name  = "CentOS7"
  flavor_name = "m1.small"
  key_pair    = openstack_compute_keypair_v2.test-keypair.name
  security_groups = [
    openstack_networking_secgroup_v2.secgroup_1.name
  ]

  metadata = {
    server = "web",
    color  = "blue"
  }

  network {
    name = data.openstack_networking_network_v2.shared_network.name
  }
}

# Floating IP
resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool = data.openstack_networking_network_v2.public_network.name
}

data "openstack_networking_port_v2" "port_1" {
  device_id  = openstack_compute_instance_v2.instance01.id
  network_id = openstack_compute_instance_v2.instance01.network.0.uuid
}

# Floating IP를 Port에 연결
resource "openstack_networking_floatingip_associate_v2" "fip_assoc_1" {
  floating_ip = openstack_networking_floatingip_v2.floatip_1.address
  port_id     = data.openstack_networking_port_v2.port_1.id
}