#!/bin/bash
# Desc: K8s master deploy init
# Author: MoYuanhui
# Version: 1.0.0
# Date: 2019-3-11


# sudo passwd root
# sudo vi /etc/ssh/sshd_config
# PermitRootLogin yes
# sudo service ssh restart



docker load < busybox.tar
docker load < cni-v2.0.4.tar
docker load < defaultbackend_1.3.tar
docker load < etcd-amd64_3.1.12.tar
docker load < flannel-0.9.1.tar
docker load < k8s-dns-dnsmasq-nanny-amd64-1.14.8.tar
docker load < k8s-dns-kube-dns-amd64.tar
docker load < k8s-dns-sidecar-amd64.tar
docker load < kube-apiserver-amd64_v1.10.1.tar
docker load <  kube-controller-manager-amd64_v1.10.1.tar
docker load < kube-proxy-amd64_v1.10.1.tar
docker load < kubernetes-dashboard-amd64.tar
docker load < kube-scheduler-amd64_v1.10.1.tar
docker load < nfs-client-provisioner.tar
docker load < node-v3.0.5.tar
docker load < tiller-v2.8.2.tar


apt-get install -y kubelet-1.10.1 kubeadm-1.10.1 kubectl-1.10.1 --allow-unauthenticated





# 设置yum依赖包
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# 设置阿里云镜像
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add

add-apt-repository \
     "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/$(. /etc/os-release; echo "$ID") \
     $(lsb_release -cs) \
     stable"

apt-get update

apt-cache madison docker-ce

# 安装docker指定版本
apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 18.06 | head -1 | awk '{print $3}')

# 设置docker开机启动，添加到root用户组
gpasswd -a root docker

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

# 安装k8s相关组件
yum install -y kubelet-1.11.1 kubeadm-1.11.1 

# 设置开机启动
systemctl enable kubelet

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

sed -i "s,ExecStart=$,Environment=\"KUBELET_EXTRA_ARGS=--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1\"\nExecStart=,g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# 配置转发参数
mkdir -p /etc/sysctl.d/
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF

# /etc/sysconfig/network脚本中添加 FORWARD_IPV4="YES"


# 加载系统配置
sysctl --system

# 安装nfs依赖
yum install -y nfs-utils rpcbind

# 设置nfs开机启动
systemctl enable nfs;systemctl enable rpcbind;
systemctl start nfs;systemctl start rpcbind;

echo "1" > /proc/sys/net/ipv4/ip_forward
# kubeadm 初始化镜像
kubeadm init --kubernetes-version=v1.11.0 --pod-network-cidr=10.244.0.0/16

# 配置kubectl认证信息
export KUBECONFIG=/etc/kubernetes/admin.conf

# 安装Flannel网络
mkdir -p /etc/cni/net.d/
cat > /etc/cni/net.d/10-flannel.conf << EOF
{
“name”: “cbr0”,
“type”: “flannel”,
“delegate”: {
“isDefaultGateway”: true
}
}
EOF

mkdir -p /usr/share/oci-umount/oci-umount.d 
mkdir /run/flannel/
cat > /run/flannel/subnet.env <<EOF
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.1.0/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF

# 创建flannel.yml配置文件
cat > ~/flannel.yaml << EOF
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
rules:
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes/status
    verbs:
      - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "type": "flannel",
      "delegate": {
        "isDefaultGateway": true
      }
    }
  net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      hostNetwork: true
      nodeSelector:
        beta.kubernetes.io/arch: amd64
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni
        image: quay.io/coreos/flannel:v0.9.1-amd64
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conf
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.9.1-amd64
        command: [ "/opt/bin/flanneld", "--ip-masq", "--kube-subnet-mgr" ]
        securityContext:
          privileged: true
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
        - name: run
          hostPath:
            path: /run
        - name: cni
          hostPath:
            path: /etc/cni/net.d
        - name: flannel-cfg
          configMap:
            name: kube-flannel-cfg
EOF
kubectl create -f ~/flannel.yaml

# 查看node信息
kubectl get nodes

# 安装git
yum install -y git

# git clone kubernetes-dashboard
git clone https://github.com/moyuanhui/kubernetes-dashboard.git


# 安装kubernetes-dashboard
kubectl create -f ./kubernetes-dashboard -n kube-system

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# 输出dashboard访问信息
echo "Visit http://ip:30090 to use your kubernetes-dashboard"


sudo mkdir /etc/docker
sudo mkdir -p /data/docker

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -  (获取公钥，显示ok即表示正确）
sudo add-apt-repository \
    "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) \
    stable" 


cat kube_apt_key.gpg | sudo apt-key add -

apt-get update

apt-get install -y \

    apt-transport-https \

    ca-certificates \

    curl \

    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \

   "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \

   $(lsb_release -cs) \

   stable"

apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')


cat kube_apt_key.gpg | apt-key add -

echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-$(lsb_release -cs) main" >> /etc/apt/sources.list

apt-get update

apt-get install -y kubelet kubeadm kubectl


apt-get update && apt-get install -y apt-transport-https

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list

deb http://apt.kubernetes.io/ kubernetes-xenial main

EOF

apt-get update

apt-get install -y kubelet kubeadm kubectl



cat kube_apt_key.gpg | apt-key add -

echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-$(lsb_release -cs) main" >> /etc/apt/sources.list

apt-get update

apt-get install -y kubelet kubeadm kubectl

add-apt-repository \
     "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/$(. /etc/os-release; echo "$ID") \
     $(lsb_release -cs) \
     stable"

echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-$(lsb_release -cs) main" | sudo tee -a /etc/apt/sources.list
deb [arch=amd64] https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main


sed -i "s,ExecStart=$,Environment=\"KUBELET_EXTRA_ARGS=--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1\"\nExecStart=,g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf


