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

kubadm集群版本教程参考

```txt
https://chen2ha.blog.csdn.net/article/details/122984097
```

配置IPVS

```bash
cat <<-EOF >/etc/sysconfig/modules/ipvs.modules
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules 
source /etc/sysconfig/modules/ipvs.modules 

```

安装ipset软件包

```bash
yum install -y ipset ipvsadm
```

```bash
#!/bin/bash

. /etc/rc.d/init.d/functions
export LANG=zh_CN.UTF-8

set -e

#--------------------------------------------
# 此脚本用于Centos7自动部署k8s服务
# 安装K8S前先去查看k8s仪表板最新支持的版本
# 因为仪表板支持的版本落后于最新版本
# 得根据仪表板支持的最新版本进行安装
# 2022年04月11日
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
  action "完成禁用SElinux" /bin/true
 
}


#关闭交换分区
swapoff(){
  msg "green" "关闭交换分区"
  sed -i 's/.*swap.*/#&/' /etc/fstab
  sudo swapoff -a
  action "完成禁用交换分区" /bin/true
}

#配置K8S内核参数
sysctl.k8s(){
msg "green" "配置K8S内核参数"
cat << EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF

modprobe br_netfilter
sysctl --system
action "完成k8s 内核修改" /bin/true
}

#修改系统源为国内源
change.repos.ali(){
msg "green" "修改系统源为国内源"
mv /etc/yum.repos.d/ /etc/yum.repos.d.initial.back
mkdir /etc/yum.repos.d/
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

sed -i 's@http://mirrors.cloud.aliyuncs.com@http://mirrors.aliyun.com@g' /etc/yum.repos.d/CentOS-Base.repo


cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum clean all
yum makecache -y

action "完成yum源修改" /bin/true

}

#containerd
install.containerd(){
  msg "green" "安装containerd"
  yum install -y containerd.io
  if ! type containerd >/dev/null 2>&1; then
    msg "red" "安装containerd 失败"
    action "安装containerd " /bin/false
    exit 1
  fi

  containerd config default > /etc/containerd/config.toml
  sed -i "s@k8s.gcr.io/pause:3.5@registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.5@g;s@SystemdCgroup = false@SystemdCgroup = true@g" /etc/containerd/config.toml

cat <<EOF > /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime for kubernetes
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd --config /etc/containerd/config.toml

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

systemctl enable containerd
systemctl start containerd
systemctl status containerd

msg "green" "配置 crictl"

cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

action "完成安装containerd" /bin/true

}

#安装docker
install.docker(){
  msg "green" "安装docker"
  yum -y erase podman buildah
  yum install -y yum-utils device-mapper-persistent-data lvm2 net-tools
  # yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

  yum install -y docker-ce
  if ! type docker >/dev/null 2>&1; then
      msg "red" "安装docker-ce 失败"
      action "安装docker-ce " /bin/false
      exit 1
    fi

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
action "完成安装docker" /bin/true

}

#安装kubectl、kubelet、kubeadm
install.k8s(){
 msg "green" "安装k8s命令工具..."
 yum install -y kubectl kubelet kubeadm

 systemctl enable kubelet
 systemctl start kubelet
 action "完成安装k8s组件" /bin/true
}


config.k8s(){
  msg "green" "配置k8s中..."
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
}

network.k8s(){
  msg "green" "安装calico网络.."
  ## calico 在v3.24.0 开始添加了一个新的功能需要挂载 bpffs 目录，目前没有找到这个问题的处理方式，降级到 3.23.1
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
}

cluster-info.k8s(){
kubectl cluster-info
}

#初始化k8s
initial.k8s(){
  container=$1

  msg "green" "初始化k8s中..."
  k8sversion=$(kubeadm version | grep -Eo 'v[0-9].[0-9]{2}.[0-9]{1,2}')
  k8sApi=$(hostname -I | awk -F' ' '{print $1}')

  if [ ${container} == "docker" ];then
  kubeadm init \
  --apiserver-advertise-address=$k8sApi \
  --apiserver-cert-extra-sans=127.0.0.1 \
  --image-repository=registry.aliyuncs.com/google_containers \
  --ignore-preflight-errors=all \
  --kubernetes-version=$k8sversion \
  --service-cidr=10.10.0.0/16 \
  --pod-network-cidr=10.18.0.0/16
  else
  kubeadm init \
  --apiserver-advertise-address=$k8sApi \
  --apiserver-cert-extra-sans=127.0.0.1 \
  --image-repository=registry.aliyuncs.com/google_containers \
  --ignore-preflight-errors=all \
  --kubernetes-version=$k8sversion \
  --cri-socket /run/containerd/containerd.sock\
  --v 5 \
  --service-cidr=10.10.0.0/16 \
  --pod-network-cidr=10.18.0.0/16
  fi

if [ $? -eq 0 ];then

  config.k8s
  network.k8s
  cluster-info.k8s

  action "完成k8s初始化" /bin/true
else
  action "k8s初始化失败" /bin/false
fi
}


main(){
  type=$(whiptail --title "容器类型选择" --menu "请您选择容器工具" 10 60 4 \
                "Docker" "docker" \
                "Containerd" "containerd" 3>&1 1>&2 2>&3)
  if [ ${type} == "docker" ]; then
    msg "green" ${type}
    selinuxoff
    swapoff
    sysctl.k8s
    change.repos.ali
    install.docker
    install.k8s
    initial.k8s ${type}
  else
    msg "green" "containerd"
    selinuxoff
    swapoff
    sysctl.k8s
    change.repos.ali
    install.containerd
    install.k8s
    initial.k8s "containerd"
  fi

}

main


```

### 单节点部署完成之后去掉 污点

当创建单机版的 k8s 时，这个时候 master 节点是默认不允许调度 pod 。

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

查看

```bash
kubectl describe node master | grep Taints    //查看修改后的状态
Taints:             <none>
```

将 master 标记为可调度即可

---
Taint（污点）和 Toleration（容忍）可以作用于 node 和 pod 上，其目的是优化 pod 在集群间的调度，这跟节点亲和性类似，只不过它们作用的方式相反，具有 taint 的 node 和 pod 是互斥关系，而具有节点亲和性关系的 node 和 pod 是相吸的。另外还有可以给 node 节点设置 label，通过给 pod 设置 nodeSelector 将 pod 调度到具有匹配标签的节点上。

Taint 和 toleration 相互配合，可以用来避免 pod 被分配到不合适的节点上。每个节点上都可以应用一个或多个 taint ，这表示对于那些不能容忍这些 taint 的 pod，是不会被该节点接受的。如果将 toleration 应用于 pod 上，则表示这些 pod 可以（但不要求）被调度到具有相应 taint 的节点上。

### 设置污点

```bash
NoSchedule:  一定不能被调度
PreferNoSchedule:  尽量不要调度
NoExecute:  不仅不会调度, 还会驱逐Node上已有的Pod

kubectl taint nodes node1 key1=value1:NoSchedule
kubectl taint nodes node1 key1=value1:NoExecute
kubectl taint nodes node1 key2=value2:NoSchedule
```

### 查看污点

```bash
kubectl describe node node1
```

### 删除污点

```bash
kubectl taint node node1 key1:NoSchedule-   # 这里的key可以不用指定value
kubectl taint node node1 key1:NoExecute-
kubectl taint node node1 key1-              # 删除指定key所有的effect
kubectl taint node node1 key2:NoSchedule-
```

### 安装失败清理环境重新安装

```bash
kubeadm reset
```

### 开启IPVS，修改ConfigMap的kube-system/kube-proxy中的模式为ipvs

```bash
kubectl edit cm kube-proxy -n kube-system
```

```yaml
mode: "ipvs"
```

### 开启strictARP

```yaml
    ipvs:
      excludeCIDRs: null
      minSyncPeriod: 0s
      scheduler: ""
      strictARP: true   # 将false改为true
```

### 重启kube-proxy

```bash
kubectl get pod -n kube-system | grep kube-proxy | awk '{system("kubectl delete pod "$1" -n kube-system")}'
```
