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
yum install -y docker-ce-18.06.0.ce

# 设置docker开机启动，添加到root用户组
systemctl enable docker
systemctl start docker
usermod -aG docker $USER

# 输出docker版本
#docker version

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

# 安装依赖
yum install -y cri-tools-1.11.0 socat-1.7.3.2 libnetfilter_conntrack-1.0.4

# 安装k8s相关组件
yum install -y kubernetes-cni-0.6.0 kubeadm-1.11.1 kubelet-1.11.2 kubectl-1.11.2

# 设置开机启动
systemctl enable kubelet;systemctl start kubelet

# docker pull下载相关镜像，并指定新的tag
images=(kube-proxy-amd64:v1.11.0 kube-scheduler-amd64:v1.11.0 kube-controller-manager-amd64:v1.11.0 kube-apiserver-amd64:v1.11.0
etcd-amd64:3.2.18 coredns:1.1.3 pause-amd64:3.1 kubernetes-dashboard-amd64:v1.8.3 k8s-dns-sidecar-amd64:1.14.9 k8s-dns-kube-dns-amd64:1.14.9
k8s-dns-dnsmasq-nanny-amd64:1.14.9 )
for imageName in ${images[@]} ; do
    docker pull keveon/$imageName
    docker tag keveon/$imageName k8s.gcr.io/$imageName
    docker rmi keveon/$imageName
done
docker tag da86e6ba6ca1 k8s.gcr.io/pause:3.1

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

# less /proc/sys/net/ipv4/ip_forward
echo "1" > /proc/sys/net/ipv4/ip_forward

# 加载系统配置
sysctl --system

# 安装nfs依赖
yum install -y nfs-utils rpcbind

# 设置nfs开机启动
systemctl enable nfs;systemctl enable rpcbind;
systemctl start nfs;systemctl start rpcbind;

# 加入集群（master执行，然后拿到秘钥信息，再到node节点执行加入操作，类似于kubectl join ..）
# kubeadm token create --print-join-command
