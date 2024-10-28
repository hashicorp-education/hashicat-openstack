output "info" {
  value = {
    ssh = "ssh -i ../terraform-code/bastion_ssh_private ubuntu@${aws_instance.openstack.public_ip}"
    console   = "http://${aws_instance.openstack.public_ip}"
    password  = nonsensitive(random_password.password.result)
  }
}

output "openstack_ip" {
  value = aws_instance.openstack.public_ip
}