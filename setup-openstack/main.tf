data "aws_caller_identity" "current" {}

resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.example.id
  availability_zone       = data.aws_availability_zones.available.names.0
  cidr_block              = cidrsubnet(aws_vpc.example.cidr_block, 8, 0) // "10.0.0.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.example.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "public" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public" {
  allocation_id = aws_eip.public.id
  subnet_id     = aws_subnet.public.id
}

// SG
resource "aws_security_group" "example" {
  name   = "example"
  vpc_id = aws_vpc.example.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "example_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

resource "aws_security_group_rule" "openstack_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

resource "aws_security_group_rule" "openstack_network" {
  type              = "ingress"
  from_port         = 9696
  to_port           = 9696
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

resource "aws_security_group_rule" "openstack_object_store" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

resource "aws_security_group_rule" "openstack_instance_console" {
  type              = "ingress"
  from_port         = 6080
  to_port           = 6080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

// key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "ssh_private" {
  content  = tls_private_key.ssh.private_key_pem
  filename = "${path.module}/../terraform-code/bastion_ssh_private"
}

resource "random_id" "key_id" {
  keepers = {
    ami_id = tls_private_key.ssh.public_key_openssh
  }

  byte_length = 8
}

resource "aws_key_pair" "ssh" {
  key_name   = "key-${random_id.key_id.hex}"
  public_key = tls_private_key.ssh.public_key_openssh
}

// EC2
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "openstack" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh.key_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.example.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 200
  }

  tags = {
    Name = "openstack"
  }
}

resource "random_password" "password" {
  length  = 10
  special = false
}

resource "local_file" "install_config" {
  content = templatefile("${path.module}/local.conf.tpl", {
    public_ip = aws_instance.openstack.public_ip
    password  = random_password.password.result
  })
  filename = "${path.module}/local.conf"
}

resource "local_file" "install_script" {
  content = templatefile("${path.module}/script.sh.tpl", {
    public_ip        = aws_instance.openstack.public_ip
    config_file_name = local_file.install_config.filename
  })
  filename = "${path.module}/script.sh"
}

resource "terraform_data" "openstack" {
  depends_on = [
    aws_nat_gateway.public
  ]

  triggers_replace = [
    aws_instance.openstack.id
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    host        = aws_instance.openstack.public_ip
  }

  provisioner "file" {
    source      = local_file.install_config.filename
    destination = "/tmp/local.conf"
  }

  provisioner "file" {
    source      = local_file.install_script.filename
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh"
    ]
  }
}

resource "local_file" "openstack_info_tfvars" {
  content  = <<-EOF
    openstack_url = "http://${aws_instance.openstack.public_ip}:80"
    openstack_password = "${random_password.password.result}"
  EOF
  filename = "${path.module}/../terraform-code/openstack_info.auto.tfvars"
}