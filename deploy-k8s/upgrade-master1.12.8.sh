#!/bin/bash
# Desc: 升级K8S版本
# Author: MoYuanhui
# Version: 1.0.0
# Date: 2019-07-13

# 升级kubeadm kubelet kubectl 到指定版本
yum install -y kubeadm-1.12.8-0 kubelet-1.12.8-0  kubectl-1.12.8-0  --disableexcludes=kubernetes

# 拉取镜像
docker pull mirrorgooglecontainers/etcd:3.2.24
docker pull  mirrorgooglecontainers/kube-controller-manager:v1.12.8
docker pull  mirrorgooglecontainers/kube-apiserver:v1.12.8
docker pull  mirrorgooglecontainers/kube-scheduler:v1.12.8
docker pull coredns/coredns:1.2.2
docker pull mirrorgooglecontainers/kube-apiserver-amd64:v1.12.8 
docker pull mirrorgooglecontainers/kube-scheduler-amd64:v1.12.8 
docker pull mirrorgooglecontainers/kube-proxy:v1.12.8
docker pull mirrorgooglecontainers/kube-proxy-amd64:v1.12.8

ooglecontainers/etcd:3.2.24 k8s.gcr.io/etcd:3.2.24
docker tag  mirrorgooglecontainers/kube-controller-manager:v1.12.8 k8s.gcr.io/kube-controller-manager:v1.12.8
docker tag  mirrorgooglecontainers/kube-apiserver:v1.12.8 k8s.gcr.io/kube-apiserver:v1.12.8
docker tag  mirrorgooglecontainers/kube-scheduler:v1.12.8 k8s.gcr.io/kube-scheduler:v1.12.8
docker tag coredns/coredns:1.2.2 k8s.gcr.io/coredns:1.2.2
docker tag mirrorgooglecontainers/kube-apiserver-amd64:v1.12.8  k8s.gcr.io/kube-apiserver-amd64:v1.12.8 
docker tag mirrorgooglecontainers/kube-scheduler-amd64:v1.12.8   k8s.gcr.io/kube-scheduler-amd64:v1.12.8 
docker tag mirrorgooglecontainers/kube-proxy:v1.12.8 k8s.gcr.io/kube-proxy:v1.12.8
docker tag mirrorgooglecontainers/kube-proxy-amd64:v1.12.8  k8s.gcr.io/kube-proxy-amd64:v1.12.8 



# 执行升级计划
kubeadm upgrade apply v1.12.8

# 获取kubelet版本配置信息
kubeadm upgrade node config --kubelet-version v1.12.8

# 重新加载daemon
systemctl daemon-reload && systemctl restart kubelet

# 重启kubelet
# systemctl restart kubelet