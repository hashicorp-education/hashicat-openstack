#!/bin/bash

#### SWAP
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

#### Tool install
sudo apt-get update
sudo apt install git bridge-utils net-tools -y

#### Delete Mysql
apt-get purge mysql-server
apt-get purge mysql*
rm -rf /var/lib/mysql/ /etc/mysql/

#### Stack Account
sudo useradd -s /bin/bash -d /opt/stack -m stack
sudo chown stack:stack -R /opt/stack/
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo chmod 755 /opt/stack

#### Virtual floating(public) ip
sudo brctl addbr mybr0
sudo ifconfig mybr0 192.168.100.1 netmask 255.255.255.0 up
sudo ip link set mybr0 up

sudo iptables -I FORWARD -j ACCEPT
sudo iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -j MASQUERADE
sudo ip addr add ${public_ip}/32 dev lo

#### Devstack install as stack user
sudo -H -u stack git clone https://opendev.org/openstack/devstack /opt/stack/devstack
sudo -H -u stack cp /tmp/local.conf /opt/stack/devstack/local.conf

#### Install Openstack as stack user
cd /opt/stack/devstack
sudo -H -u stack /opt/stack/devstack/stack.sh

#### Run OpenStack as stack user
# source openrc $username $project_name
# sudo su - stack
# cd /opt/stack/devstack
# source openrc admin admin

#### Check as stack user
# env | grep OS_