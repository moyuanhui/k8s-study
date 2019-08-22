#修改hostname 
vim /etc/hostanme  -- k8s-master-01

# 设置docker repo源
cat > /etc/yum.repos.d/docker.repo <<EOF
[docker]
name=Docker Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker/yum/repo/centos7
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker/yum/gpg
EOF

# 安装docker 1.13.1
yum -y install docker-engine-1.13.1 --disableexcludes=docker

# 启动docker
systemctl enable docker;systemctl start docker;

# 安装master
./k8s master


# 查看toekn
./k8s master -t

# 在node上执行,初始化node节点并加入到集群
./k8s node
? Please input k8s master ip address:  输入master ip 地址，记得开放6443端口
? Please enter the host name:  输入节点名称
? Please input k8s master join token, use k8s master -token get:  输入 master token 口令
? Please input k8s master ca cert hash token, use k8s master -token get:  输入 master ca token 口令

# dashboard地址 https://masterip:32000 或者 https://masterip:30000

版本及release note：

v1.14.1 版本release note
修改kubeadm 证书到期时间，延迟至10年
优化linux内核，解决Failed to watch directory xxxx no space left on device问题，同时优化kubelet参数，防止系统资源不够时将kubernet系统组件驱逐
calico v3.7.2 使用typha作为存储，k8s数据存储模式超过50各节点推荐启用typha,Typha组件可以帮助Calico扩展到大量的节点，而不会对Kubernetes API服务器造成过度的影响。
使用helm v2.13.1 管理kubernetes，并启用tls进行加密访问，证书在/root/.helm目录下
dashboard v1.10.1
集成promethus监控系统！使用metrics取缔heapster，grafana管理账户密码 admin/admin
高可用的promethus
高可用的alertmanager告警
node-exporter kube-state-metrics grafana, 用operator实现


# helm 
$ wget -qO- https://kubernetes-helm.storage.googleapis.com/helm-v2.9.1-linux-amd64.tar.gz | tar -zx
$ sudo mv linux-amd64/helm /usr/local/bin/
$ kubectl -n kube-system create sa tiller
$ kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
$ helm init --service-account tiller

$ kubectl -n kube-system patch deploy  tiller-deploy -p '{"spec":{"template":{"spec":{"containers":[{"name":"tiller","image":"moyuanhui/gcr.io.kubernetes-helm.tiller:v2.9.1"}]}}}}'
