Helm Tiller Server
Helm是Kubernetes Chart的管理工具,Kubernetes Chart是一套预先组态的Kubernetes资源套件。
其中Tiller Server主要负责接收来至Client的指令,并通过kube-apiserver与Kubernetes集群做沟通,根据Chart定义的内容,
来产生与管理各种对应API物件的Kubernetes部署文件(又称为Release)。

首先在k8s-m1安装Helm tool：
```
$ wget -qO- https://kubernetes-helm.storage.googleapis.com/helm-v2.9.1-linux-amd64.tar.gz | tar -zx
$ sudo mv linux-amd64/helm /usr/local/bin/
```
另外在所有node机器安裝 socat(用于端口转发)：

yum install -y socat

接着初始化 Helm(这边会安装 Tiller Server)：
```
$ kubectl -n kube-system create sa tiller
$ kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
$ helm init --service-account tiller
...
Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.
Happy Helming!
```
这边默认helm的部署的镜像是gcr.io/kubernetes-helm/tiller:v2.9.1,如果拉取不了可以使用命令修改成国内能拉取到的镜像
```
kubectl -n kube-system patch deploy  tiller-deploy -p '{"spec":{"template":{"spec":{"containers":[{"name":"tiller","image":"moyuanhui/gcr.io.kubernetes-helm.tiller:v2.9.1"}]}}}}'
```
查看tiller的pod
```
 kubectl -n kube-system get po -l app=helm
NAME                             READY     STATUS    RESTARTS   AGE
tiller-deploy-5f789bd9f7-tzss6   1/1       Running   0          29s

$ helm version
Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
```

测试
``` 
helm install --name demo --set Persistence.Enabled=false stable/jenkins

```
```
$ kubectl get po,svc  -l app=demo-jenkins
NAME                           READY     STATUS    RESTARTS   AGE
demo-jenkins-7bf4bfcff-q74nt   1/1       Running   0          2m

NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
demo-jenkins         LoadBalancer   10.103.15.129    <pending>     8080:31161/TCP   2m
demo-jenkins-agent   ClusterIP      10.103.160.88   <none>        50000/TCP        2m
```
<!-- helm Release -->
https://github.com/helm/helm/releases

https://github.com/helm/charts

<!-- coredns -->
kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools

<!-- helm官网 -->
<!-- https://helm.sh -->