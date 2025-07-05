#!/bin/bash

# 设置静态IP地址
# 只针对本地Rocky虚拟机
echo "Setting static IP address for ens160..."
nmcli connection modify ens160 ipv4.addresses "192.168.66.12/24"
nmcli connection modify ens160 ipv4.gateway "192.168.66.200"
nmcli connection modify ens160 ipv4.dns "114.114.114.114,8.8.8.8,8.8.4.4"
nmcli connection modify ens160 ipv4.method manual
nmcli connection up ens160

# 关闭ens192网卡
echo "Disabling ens192..."
nmcli connection down ens192
nmcli d d ens192
nmcli d r ens160
nmcli c r ens160

# 更换yum源为阿里云
echo "Changing YUM repository to Aliyun..."
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak /etc/yum.repos.d/rocky*.repo

dnf makecache

# 安装常用软件
echo "Installing common software..."
dnf install -y epel-release
dnf install -y vim git wget curl net-tools lrzsz tree zip unzip vim telnet proxychains-ng
sed -i 's/^socks4/# socks4/' /etc/proxychains.conf
echo "socks5 	192.168.3.14 20800" >> /etc/proxychains.conf


# 禁用 Selinux
echo "Disabling SELinux..."
setenforce 0
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
grubby --update-kernel ALL --args selinux=0

# 禁用防火墙
echo "Disabling firewall..."
systemctl stop firewalld
systemctl disable firewalld

# 设置时区为上海
echo "Setting timezone to Shanghai..."
timedatectl set-timezone Asia/Shanghai

# 关闭 swap 分区
echo "Disabling swap partition..."
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

# 设置主机名
echo "Setting hostname to k8s-node1..."
hostnamectl set-hostname k8s-node1

echo "Setting hostname to k8s-node1..."
cat >> /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.66.11 k8s-master
192.168.66.12 k8s-node1
192.168.66.13 k8s-node2
EOF

# 安装 ipvs
echo "Installing IPVS..."
yum install -y ipvsadm
# 开启路由转发
echo "Enabling IP forwarding..."
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p
# 加载 bridge
echo "Loading bridge kernel module..."

yum install -y epel-release
yum install -y bridge-utils

modprobe br_netfilter
echo 'br_netfilter' >> /etc/modules-load.d/bridge.conf
echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
sysctl -p

