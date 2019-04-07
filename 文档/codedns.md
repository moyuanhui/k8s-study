### DNS简介
DNS 组件作为 Kubernetes 中服务注册和发现的一个必要组件，起着举足轻重的作用，是我们在安装好 Kubernetes 集群后部署的第一个容器化应用。
### kube-dns
在我们安装Kubernetes集群的时候就已经安装了kube-dns插件，这个插件也是官方推荐安装的。通过将 Service 注册到 DNS 中，Kuberentes 可以为我们提供一种**简单的服务注册发现与负载均衡**方式，这里我们需要安装比较强大的**CoreDNS**
### CoreDNS
目前，CoreDNS只支持Kubernetes1.6以上版本,[coredns官方地址](https://coredns.io/ "coredns官方地址")，目的主要是做服务发现注册于负载均衡使用。
### 安装部署
1. 下载coredns资源文件
2.执行deploy.sh脚本
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;deploy.sh 是一个**用于在已经运行kube-dns的集群**中生成运行CoreDNS部署文件（manifest）的工具脚本。它使用 coredns.yaml.sed文件作为模板，创建一个ConfigMap和CoreDNS的deployment，然后更新集群中已有的kube-dns服务的selector使用CoreDNS的deployment。重用已有的服务并不会在服务的请求中发生冲突。
&nbsp;&nbsp;&nbsp;&nbsp;deploy.sh文件并不会删除kube-dns的deployment或者replication controller。如果要删除kube-dns，你必须在部署CoreDNS后手动的删除kube-dns。
3. 使用CoreDNS替换Kube-DNS
```
./deploy.sh | kubectl apply -f .
kubectl delete --namespace=kube-system deployment kube-dns ##删除kube-dns
```
注意：**建议在部署CoreDNS后删除kube-dns。否则如果CoreDNS和kube-dns同时运行，服务查询可能会随机的在CoreDNS和kube-dns之间产生。**

没有安装RBAC的情况，你需要编辑生成的结果yaml文件，当然我们是**做了RBAC**
- 从yaml文件的Deployment部分删除 serviceAccountName: coredns
- 删除 ServiceAccount、 ClusterRole和 ClusterRoleBinding 部分
**部署完毕，我们在命名空间kube-system下可以看到刚刚安装的coredns，并且kube-dns已经被删除**

### 验证
````
It can be tested with the following:

1. Launch a Pod with DNS tools:

kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools

2. Query the DNS server:

/ # host kubernetes
```