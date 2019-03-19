#!/bin/bash

yum -y update
yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce-18.09.2
sudo systemctl start docker
sudo systemctl enable docker
echo `docker version`
