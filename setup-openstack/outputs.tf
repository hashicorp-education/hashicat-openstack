output "info" {
  value = {
    client_ip = "ssh -i ./ssh_private ubuntu@${aws_instance.openstack.public_ip}"
    console   = "http://${aws_instance.openstack.public_ip}"
    password  = nonsensitive(random_password.password.result)
  }
}