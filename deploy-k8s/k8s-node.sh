#!/bin/bash
# Desc: K8s node deploy init
# Author: MoYuanhui
# Version: 1.0.0
# Date: 2019-3-11


# 设置yum依赖包
yum install -y yum-utils device-mapper-persistent-data lvm2
# 设置阿里云镜像
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# 安装docker指定版本
yum install -y docker-ce-18.06.3.ce 

# 设置docker开机启动，添加到root用户组
systemctl enable docker
systemctl start docker
usermod -aG docker $USER

# 输出docker版本
#docker version

docker pull moyuanhui/flannel:v0.11.0-amd64
docker tag moyuanhui/flannel:v0.11.0-amd64 quay.io/coreos/flannel:v0.11.0-amd64

# 配置阿里云国内镜像源
mkdir -p /etc/yum.repos.d
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

# 安装所需依赖
yum -y install epel-release
yum clean all
yum makecache


# 安装k8s相关组件
yum install -y kubeadm-1.12.8 kubelet-1.12.8 kubectl-1.12.8

# 设置开机启动
systemctl enable kubelet



# 关闭swap分区
swapoff -a && sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

# 关闭防火墙与SELinux 
systemctl disable --now firewalld NetworkManager
setenforce 0
sed -ri '/^[^#]*SELINUX=/s#=.+$#=disabled#' /etc/selinux/config

# 配置转发参数
mkdir -p /etc/sysctl.d/
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF


# 安装Flannel网络
mkdir -p /etc/cni/net.d/
cat > /etc/cni/net.d/10-flannel.conf << EOF
{
    "name":"cbr0",
    "type":"flannel",
    "delegate":{
        "isDefaultGateway":true
    }
}
EOF

mkdir -p /usr/share/oci-umount/oci-umount.d 
mkdir -p /run/flannel/
cat > /run/flannel/subnet.env <<EOF
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.1.0/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF


# 加载系统配置
sysctl --system

echo "1" > /proc/sys/net/ipv4/ip_forward

# 安装nfs依赖
yum install -y nfs-utils rpcbind

# 设置nfs开机启动
systemctl enable nfs;systemctl enable rpcbind;
systemctl start nfs;systemctl start rpcbind;

# 加入集群（master执行，然后拿到秘钥信息，再到node节点执行加入操作，类似于kubectl join ..）
# kubeadm token create --print-join-command
