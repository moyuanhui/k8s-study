#!/bin/bash
# Desc: 升级K8S版本
# Author: MoYuanhui
# Version: 1.0.0
# Date: 2019-07-13

# kubectl drain node1 --ignore-daemonsets --force
# kubectl uncordon node1

# 升级kubeadm kubelet kubectl 到指定版本
# yum upgrade -y kubeadm-1.12.8-0 kubelet-1.12.8-0  kubectl-1.12.8-0  --disableexcludes=kubernetes


# 拉取镜像
docker pull coredns/coredns:1.2.2
docker pull mirrorgooglecontainers/kube-proxy:v1.12.8
docker pull mirrorgooglecontainers/kube-proxy-amd64:v1.12.8

docker pull hub.hengkangit.com:6337/hk_docker/kube-proxy:v1.12.8
docker tag hub.hengkangit.com:6337/hk_docker/kube-proxy:v1.12.8 k8s.gcr.io/kube-proxy:v1.12.8

docker pull hub.hengkangit.com:6337/hk_docker/coredns:1.2.2
docker tag hub.hengkangit.com:6337/hk_docker/coredns:1.2.2 k8s.gcr.io/coredns:1.2.2



docker tag mirrorgooglecontainers/kube-proxy-amd64:v1.12.8  k8s.gcr.io/kube-proxy-amd64:v1.12.8 
docker tag coredns/coredns:1.2.2 k8s.gcr.io/coredns:1.2.2


# # 获取kubelet版本配置信息
# kubeadm upgrade node config --kubelet-version v1.12.8

# # 重新加载daemon
# systemctl daemon-reload  && systemctl restart kubelet

# # 重启kubelet
# 

cd /etc/kubernetes
rm admin.conf
./kubeadm991.13.4 init phase kubeconfig admin --config kubeadm.yaml
cd ~/.kube
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
