#!/bin/bash

# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld

# 关闭缓存
swapoff -a
sed -i "s/\/dev\/mapper\/centos-swap/# \/dev\/mapper\/centos-swap/" /etc/fstab

# 关闭 SeLinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config
