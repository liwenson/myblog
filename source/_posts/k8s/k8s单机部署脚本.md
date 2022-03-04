---
title: k8s单机部署
date: 2022-02-11 11:22
categories:
- k8s
tags:
- k8s
---
  
  
摘要: k8s单机部署
<!-- more -->

用于k8s 实验


```
#!/bin/bash

#--------------------------------------------
# 此脚本用于Centos7自动部署k8s服务
# 安装K8S前先去查看k8s仪表板最新支持的版本
# 因为仪表板支持的版本落后于最新版本
# 得根据仪表板支持的最新版本进行安装
# 2021年10月31日
#--------------------------------------------

msg() {
  color=$1
  string=$2
  declare -A  myMap=(["green"]="\033[32m " ["red"]="\033[31m[error]" ["warn"]="\033[33m[warnning]" )
  End="\033[0m\n"
  printf "${myMap[${color}]}${string}${End}"
}


#关闭seLinux
selinuxoff(){
 msg "green" "关闭seLinux 和 防火墙 "
 sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
 setenforce 0

 systemctl disable firewalld
 systemctl stop firewalld

 echo "$(hostname -I | awk -F' ' '{print $1}') $(hostname)" >> /etc/hosts
}


#关闭交换分区
swapoff(){
 msg "green" "关闭交换分区"
 sed -i 's/.*swap.*/#&/' /etc/fstab
 sudo swapoff -a
}

#配置K8S内核参数
sysctl.k8s(){
msg "green" "配置K8S内核参数"
cat << EOF >> /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF

modprobe br_netfilter
sysctl --system
}

#修改系统源为国内源
change.repos.ali(){
msg "green" "修改系统源为国内源"
mv /etc/yum.repos.d/ /etc/yum.repos.d.initial.back
mkdir /etc/yum.repos.d/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

cat << EOF >> /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

}

#安装docker
install.docker(){
 msg "green" "安装docker"
 yum -y erase podman buildah
 yum install -y yum-utils device-mapper-persistent-data lvm2 net-tools
 yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
 yum install -y docker-ce
 systemctl enable docker
 systemctl start docker
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver":"json-file",
  "log-opts": {"max-size":"500m", "max-file":"3"},
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

 systemctl restart docker

}

#安装kubectl、kubelet、kubeadm
install.k8s(){
 msg "green" "安装k8s命令工具"
 yum install -y kubectl kubelet kubeadm
 systemctl enable kubelet
 systemctl start kubelet
}

#初始化k8s
initial.k8s(){
 msg "green" "初始化k8s"
 k8sversion=$(kubeadm version | grep -Eo 'v[0-9].[0-9]{2}.[0-9]{1,2}')
 k8sApi=$(hostname -I | awk -F' ' '{print $1}')

 kubeadm init \
 --apiserver-advertise-address=$k8sApi \
 --apiserver-cert-extra-sans=127.0.0.1 \
 --image-repository=registry.aliyuncs.com/google_containers \
 --ignore-preflight-errors=all \
 --kubernetes-version=$k8sversion \
 --service-cidr=10.10.0.0/16 \
 --pod-network-cidr=10.18.0.0/16

config.k8s
network.k8s
cluster-info.k8s
}


config.k8s(){
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
}

network.k8s(){
msg "green" "安装calico网络"
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
}

cluster-info.k8s(){
kubectl cluster-info
}


selinuxoff
swapoff
sysctl.k8s
change.repos.ali
install.docker
install.k8s
initial.k8s

```

单节点部署完成之后去掉 污点
当创建单机版的 k8s 时，这个时候 master 节点是默认不允许调度 pod 。
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```
将 master 标记为可调度即可


---
Taint（污点）和 Toleration（容忍）可以作用于 node 和 pod 上，其目的是优化 pod 在集群间的调度，这跟节点亲和性类似，只不过它们作用的方式相反，具有 taint 的 node 和 pod 是互斥关系，而具有节点亲和性关系的 node 和 pod 是相吸的。另外还有可以给 node 节点设置 label，通过给 pod 设置 nodeSelector 将 pod 调度到具有匹配标签的节点上。

Taint 和 toleration 相互配合，可以用来避免 pod 被分配到不合适的节点上。每个节点上都可以应用一个或多个 taint ，这表示对于那些不能容忍这些 taint 的 pod，是不会被该节点接受的。如果将 toleration 应用于 pod 上，则表示这些 pod 可以（但不要求）被调度到具有相应 taint 的节点上。

### 设置污点
```
NoSchedule:  一定不能被调度
PreferNoSchedule:  尽量不要调度
NoExecute:  不仅不会调度, 还会驱逐Node上已有的Pod

kubectl taint nodes node1 key1=value1:NoSchedule
kubectl taint nodes node1 key1=value1:NoExecute
kubectl taint nodes node1 key2=value2:NoSchedule
```
### 查看污点
```
kubectl describe node node1
```

### 删除污点
```
kubectl taint node node1 key1:NoSchedule-   # 这里的key可以不用指定value
kubectl taint node node1 key1:NoExecute-
kubectl taint node node1 key1-              # 删除指定key所有的effect
kubectl taint node node1 key2:NoSchedule-
```



