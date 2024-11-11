#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


#### SWAP
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

#### Tool install
sudo apt update -y

# sudo apt install software-properties-common -y
# sudo add-apt-repository ppa:deadsnakes/ppa -y
# sudo apt update -y

# sudo apt install git bridge-utils net-tools python3.9 -y
# sudo apt install python3.9-distutils python3.9-venv -y
# sudo apt upgrade python3-rtslib-fb targetcli-fb -y

# sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
# sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2

curl -sS https://bootstrap.pypa.io/get-pip.py | python3

cd /usr/lib/python3/dist-packages
sudo cp apt_pkg.cpython-38-x86_64-linux-gnu.so apt_pkg.so
cd -

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
sudo apt-get update -y
sudo apt-get install bridge-utils -y
sudo brctl addbr mybr0
sudo ifconfig mybr0 192.168.100.1 netmask 255.255.255.0 up
sudo ip link set mybr0 up

sudo iptables -I FORWARD -j ACCEPT
sudo iptables -I FORWARD -i mybr0 -j ACCEPT
sudo iptables -I FORWARD -o mybr0 -j ACCEPT

sudo iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -j MASQUERADE
sudo ip addr add ${HOST_IP}/32 dev lo

echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

#### Devstack install as stack user
sudo -H -u stack git clone https://opendev.org/openstack/devstack /opt/stack/devstack
sudo cp /root/hashicat-openstack/files/local.conf /opt/stack/devstack/local.conf
chown stack:stack /opt/stack/devstack/local.conf

#### Install Openstack as stack user
cd /opt/stack/devstack

sudo rm -rf /opt/stack/data/venv
sudo -H -u stack python3 -m venv /opt/stack/data/venv
sudo -H -u stack pip install -c /opt/stack/requirements/upper-constraints.txt -U os-testr


sudo -H -u stack /opt/stack/data/venv/bin/python -m ensurepip --upgrade
sudo -H -u stack /opt/stack/devstack/stack.sh

#### Run OpenStack as stack user
# source openrc $username $project_name
# sudo su - stack
# cd /opt/stack/devstack
# source openrc admin admin

#### Check as stack user
# env | grep OS_

exit 0