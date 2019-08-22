#!/bin/bash
# Desc: 升级K8S版本
# Author: MoYuanhui
# Version: 1.0.0
# Date: 2019-07-13

# 升级kubeadm kubelet kubectl 到指定版本
# yum list --showduplicates kubeadm --disableexcludes=kubernetes 
yum upgrade -y kubeadm-1.11.3-0 kubelet-1.11.3-0  kubectl-1.11.3-0  --disableexcludes=kubernetes

# yum list --showduplicates kubeadm --disableexcludes=kubernetes

# 拉取镜像
docker pull mirrorgooglecontainers/etcd:3.2.24
docker pull  mirrorgooglecontainers/kube-controller-manager:v1.11.3
docker pull  mirrorgooglecontainers/kube-apiserver:v1.11.3
docker pull  mirrorgooglecontainers/kube-scheduler:v1.11.3
docker pull coredns/coredns:1.2.2
docker pull mirrorgooglecontainers/kube-controller-manager-amd64:v1.11.3
docker pull mirrorgooglecontainers/kube-apiserver-amd64:v1.11.3 
docker pull mirrorgooglecontainers/kube-scheduler-amd64:v1.11.3 
docker pull mirrorgooglecontainers/kube-proxy:v1.11.3
docker pull mirrorgooglecontainers/kube-proxy-amd64:v1.11.3

# 重新打tag
docker tag mirrorgooglecontainers/etcd:3.2.24 k8s.gcr.io/etcd:3.2.24
docker tag  mirrorgooglecontainers/kube-controller-manager:v1.11.3 k8s.gcr.io/kube-controller-manager:v1.11.3
docker tag  mirrorgooglecontainers/kube-apiserver:v1.11.3 k8s.gcr.io/kube-apiserver:v1.11.3
docker tag  mirrorgooglecontainers/kube-scheduler:v1.11.3 k8s.gcr.io/kube-scheduler:v1.11.3
docker tag mirrorgooglecontainers/kube-controller-manager-amd64:v1.11.3 k8s.gcr.io/kube-controller-manager-amd64:v1.11.3
docker tag coredns/coredns:1.2.2 k8s.gcr.io/coredns:1.2.2
docker tag mirrorgooglecontainers/kube-apiserver-amd64:v1.11.3  k8s.gcr.io/kube-apiserver-amd64:v1.11.3 
docker tag mirrorgooglecontainers/kube-scheduler-amd64:v1.11.3   k8s.gcr.io/kube-scheduler-amd64:v1.11.3 
docker tag mirrorgooglecontainers/kube-proxy:v1.11.3 k8s.gcr.io/kube-proxy:v1.11.3
docker tag mirrorgooglecontainers/kube-proxy-amd64:v1.11.3  k8s.gcr.io/kube-proxy-amd64:v1.11.3 



# 执行升级计划

# kubeadm upgrade plan
kubeadm upgrade apply v1.11.3

# 获取kubelet版本配置信息
kubeadm upgrade node config --kubelet-version v1.11.3

# 重新加载daemon
systemctl daemon-reload && systemctl restart kubelet

# 重启kubelet
# systemctl restart kubelet