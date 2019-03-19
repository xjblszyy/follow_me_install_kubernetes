[TOC]

## 1.13版本k8s部署(centos)

### 0.预先准备

- 集群服务器参数

ip | 作用
---|---
10.20.0.100 | master
10.20.0.101 | slave
10.20.0.102 | slave
10.20.0.103 | slave
10.20.0.104 | slave
**-- 注意 --**：在master的主机上面要配置好.ssh/config，以及.ssh/authorized_keys。master上面能ping通所有slave，以及无密码ssh登陆，具体操作右转百度。

- 这是我的config配置文件，参阅，系统为**centos**
```
Host szyy00
    Hostname 10.20.0.100
    Port 22
    User root
Host szyy01
    Hostname 10.20.0.101
    Port 22
    User root
Host szyy02
    Hostname 10.20.0.102
    Port 22
    User root
Host szyy03
    Hostname 10.20.0.103
    Port 22
    User root
Host szyy04
    Hostname 10.20.0.104
    Port 22
    User root
```

- 关闭Swap和SeLinux功能和关闭防火墙(所有机器的，可以写成shell)

```
# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld

# 关闭缓存
swapoff -a
sed -i "s/\/dev\/mapper\/centos-swap/# \/dev\/mapper\/centos-swap/" /etc/fstab

# 关闭 SeLinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=permissive/" /etc/selinux/config

```


### 1.安装docker(所有服务器)


- Docker 要求 CentOS 系统的内核版本高于 3.10 ，查看本页面的前提条件来验证你的CentOS 版本是否支持 Docker
```
# yum uname -r
```
- 使用 root 权限登录 Centos。确保 yum 包更新到最新

```
# sudo yum update
```
- 安装需要的软件包， yum-util 提供yum-config-manager功能，另外两个是devicemapper驱动依赖的

```
# sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```
- 设置yum源

```
# sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```
- 可以查看所有仓库中所有docker版本，并选择特定版本安装

```
# yum list docker-ce --showduplicates | sort -r
```
- 安装docker

```
# sudo yum install docker-ce  #由于repo中默认只开启stable仓库，故这里安装的是最新稳定版17.12.0
# sudo yum install <FQPN>  # 例如：sudo yum install docker-ce-18.09.2
# systemctl start docker  # 启动docker
```
-启动并加入开机启动

```
# sudo systemctl start docker
# sudo systemctl enable docker
```

- 查看安装结果：
```
# docker version
# systemctl status docker
# docker run hello-world
```

- 编写shell脚本，scp到所有slave中，自动完成剩余服务器docker安装

```
[root@localhost ~]# cat send_shell.sh
#!/bin/bash

for name in $NODE_NAMES
do
	echo ">>> $name "
	scp $1 $name:./
	ssh $name "bash $1"
done
---------------------------------------------
[root@localhost ~]# cat 01.install_docker.sh
#!/bin/bash

yum -y update
yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum -y install docker-ce-18.09.2
sudo systemctl start docker
sudo systemctl enable docker
echo `docker version`
```


### 2.安装kubelet kubeadm kubectl(所有服务器)

- 添加源

```
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```
- 接着操作

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
- 安装

```
yum install -y kubelet-1.13.3 kubeadm-1.13.3 kubectl-1.13.3
```
- 设置开机自启，启动组件

```
systemctl enable kubelet && systemctl start kubelet
```

- 检验安装结果：
```
kubeadm version
kubectl version
cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl status kubelet
```
- 查看日志

```
journalctl -xefu kubelet
```


- 编写shell脚本，scp到所有slave中，自动完成剩余服务器组件安装

```
[root@localhost ~]# cat 02.install_k8s.sh
#!/bin/bash

yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet-1.13.3 kubeadm-1.13.3 kubectl-1.13.3

systemctl enable kubelet && systemctl start kubelet
```

### 3.安装对应镜像
**注意** 1:镜像版本问题；2:由于墙的作用，本方案使用打tag方式解决

- 看下该版本下的镜像名

```
kubeadm config images list --kubernetes-version v1.13.3
```


- 在master上面安装
```
# 拉取镜像
docker pull mirrorgooglecontainers/kube-apiserver:v1.13.0
docker pull mirrorgooglecontainers/kube-controller-manager:v1.13.0
docker pull mirrorgooglecontainers/kube-scheduler:v1.13.0
docker pull mirrorgooglecontainers/kube-proxy:v1.13.0
docker pull mirrorgooglecontainers/pause:3.1
docker pull mirrorgooglecontainers/etcd:3.2.24
docker pull coredns/coredns:1.2.6

# 重命名镜像标签
docker tag docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0 k8s.gcr.io/kube-proxy:v1.13.0
docker tag docker.io/mirrorgooglecontainers/kube-scheduler:v1.13.0 k8s.gcr.io/kube-scheduler:v1.13.0
docker tag docker.io/mirrorgooglecontainers/kube-apiserver:v1.13.0 k8s.gcr.io/kube-apiserver:v1.13.0
docker tag docker.io/mirrorgooglecontainers/kube-controller-manager:v1.13.0 k8s.gcr.io/kube-controller-manager:v1.13.0
docker tag docker.io/mirrorgooglecontainers/etcd:3.2.24  k8s.gcr.io/etcd:3.2.24
docker tag docker.io/mirrorgooglecontainers/pause:3.1  k8s.gcr.io/pause:3.1
docker tag docker.io/coredns/coredns:1.2.6  k8s.gcr.io/coredns:1.2.6

# 删除旧镜像
docker rmi docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0 
docker rmi docker.io/mirrorgooglecontainers/kube-scheduler:v1.13.0 
docker rmi docker.io/mirrorgooglecontainers/kube-apiserver:v1.13.0 
docker rmi docker.io/mirrorgooglecontainers/kube-controller-manager:v1.13.0 
docker rmi docker.io/mirrorgooglecontainers/etcd:3.2.24  
docker rmi docker.io/mirrorgooglecontainers/pause:3.1 
docker rmi docker.io/coredns/coredns:1.2.6 
```

- 在slave上面安装
```
# 拉取镜像
docker pull mirrorgooglecontainers/kube-proxy:v1.13.0
docker pull mirrorgooglecontainers/pause:3.1

# 重命名镜像标签
docker tag docker.io/mirrorgooglecontainers/pause:3.1  k8s.gcr.io/pause:3.1
docker tag docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0 k8s.gcr.io/kube-proxy:v1.13.0

# 删除旧镜像
docker rmi docker.io/mirrorgooglecontainers/kube-proxy:v1.13.0 
docker rmi docker.io/mirrorgooglecontainers/pause:3.1 
```

### 4.初始化master节点


- 初始化
```
kubeadm init --apiserver-advertise-address=10.20.0.100 --pod-network-cidr=192.168.16.0/20 --kubernetes-version=1.13.0

```

- 记录最后返回结果
```
kubeadm join 10.20.0.100:6443 --token yhvh33.q75v3wjqmov48yyb --discovery-token-ca-cert-hash sha256:80dc773358974aa0d8e9694ef56ca8ee7c27f8fa5ccf688b6c764befc0d34df0
```
- 设置环境变量
```
export KUBECONFIG=/etc/kubernetes/admin.conf
```
- 查看信息
```
kubectl get pods -n kube-system -o wide
```
-------------------------------------------

**查看初始化日志(如果有异常，查看日志)**
```
journalctl -xeu kubelet
```
**回退(如果需要回退，可以用此操作)**
```
kubeadm reset
```

### 5.安装flannel网络插件

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml   # 注意修改--pod-network-cidr的ip为init的ip
docker pull jmgao1983/flannel:v0.11.0-amd64
docker tag jmgao1983/flannel:v0.11.0-amd64 quay.io/coreos/flannel:v0.11.0-amd64
docker rmi jmgao1983/flannel:v0.11.0-amd64
kubectl apply -f flannel.yml
```
**注意**

修改flannel.yml文件的第127行
```
"Network": "192.168.16.0/20" # 后面的值为kubectl init的时候的ip的值
```
还要注意
```
image: quay.io/coreos/flannel:v0.11.0-amd64  # 这个image的版本要符合自己拉下来的要求
```

- 查看状态

```
[root@localhost ~]# kubectl get pods -n kube-system -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
coredns-86c58d9df4-574jq            1/1     Running   0          48m   192.168.16.3   localhost   <none>           <none>
coredns-86c58d9df4-kdzwd            1/1     Running   0          62m   192.168.16.2   localhost   <none>           <none>
etcd-localhost                      1/1     Running   0          62m   10.20.0.100    localhost   <none>           <none>
kube-apiserver-localhost            1/1     Running   0          62m   10.20.0.100    localhost   <none>           <none>
kube-controller-manager-localhost   1/1     Running   0          62m   10.20.0.100    localhost   <none>           <none>
kube-flannel-ds-amd64-zqwzx         1/1     Running   0          36s   10.20.0.100    localhost   <none>           <none>
kube-proxy-pz7rq                    1/1     Running   0          62m   10.20.0.100    localhost   <none>           <none>
kube-scheduler-localhost            1/1     Running   0          62m   10.20.0.100    localhost   <none>           <none>
```

- 在所有的slave上面进行kubectl join操作
```
kubeadm join 10.20.0.100:6443 --token yhvh33.q75v3wjqmov48yyb --discovery-token-ca-cert-hash sha256:80dc773358974aa0d8e9694ef56ca8ee7c27f8fa5ccf688b6c764befc0d34df0
```

### 6.剩余插件部署(可选)

```

安装其他监控插件Prometheus + grafana + node-exporter
master 安装：
	git clone https://github.com/redhatxl/k8s-prometheus-grafana.git  # 重新修改yaml文件中的镜像版本
node节点上拉取下面所有镜像
	docker pull prom/node-exporter:v0.17.0
	docker pull prom/prometheus:v2.7.1
	docker pull grafana/grafana:5.4.3  # 启动失败，估计版本太高了

2.2.2 采用daemonset方式部署node-exporter组件
	kubectl create -f  node-exporter.yaml 
2.2.3 部署prometheus组件
	2.2.3.1 rbac文件
		kubectl create -f  k8s-prometheus-grafana/prometheus/rbac-setup.yaml
	2.2.3.2 以configmap的形式管理prometheus组件的配置文件
		kubectl create -f  k8s-prometheus-grafana/prometheus/configmap.yaml 
	2.2.3.3 Prometheus deployment 文件
		kubectl create -f  k8s-prometheus-grafana/prometheus/prometheus.deploy.yml 
	2.2.3.4 Prometheus service文件
		kubectl create -f  k8s-prometheus-grafana/prometheus/prometheus.svc.yml 
2.2.4 部署grafana组件
	2.2.4.1 grafana deployment配置文件
		kubectl create -f   k8s-prometheus-grafana/grafana/grafana-deploy.yaml
	2.2.4.2 grafana service配置文件
		kubectl create -f   k8s-prometheus-grafana/grafana/grafana-svc.yaml
	2.2.4.3 grafana ingress配置文件
		kubectl create -f   k8s-prometheus-grafana/grafana/grafana-ing.yaml
```

