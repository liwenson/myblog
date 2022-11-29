#!/bin/bash

. /etc/rc.d/init.d/functions

export LANG=zh_CN.UTF-8

set -e

#--------------------------------------------
# 此脚本用于Centos7自动部署k8s 1.24.1服务
# 安装K8S前先去查看k8s仪表板最新支持的版本
# 因为仪表板支持的版本落后于最新版本
# 得根据仪表板支持的最新版本进行安装
# 2022年10月5日
#--------------------------------------------

version="1.24.1"

msg() {
  color=$1
  content=$2
  declare -A myMap=(["green"]="\033[32m " ["red"]="\033[31m[error]" ["warn"]="\033[33m[warnning]")
  End="\033[0m\n"
  printf "${myMap[${color}]} %s ${End}" "${content}"
}

#关闭seLinux
selinux.config() {
  msg "green" "关闭seLinux 和 防火墙 "
  sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

  if ! [ "$(getenforce)" = "Disabled" ]; then
    setenforce 0
  fi

  systemctl disable firewalld
  systemctl stop firewalld

  echo "$(hostname -I | awk -F' ' '{print $1}') $(hostname)" >>/etc/hosts
  action "完成禁用SElinux" /bin/true

}

#关闭交换分区
swap.config() {
  msg "green" "关闭交换分区"

  sed -i 's/.*swap.*/#&/' /etc/fstab

  sudo swapoff -a
  action "完成禁用交换分区" /bin/true
}

#配置K8S内核参数
sysctl.k8s() {
  msg "green" "配置K8S内核参数"

  cat <<EOF >/etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

  cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
user.max_user_namespaces=28633
vm.swappiness=0
EOF

  modprobe overlay
  modprobe br_netfilter

  sysctl -p /etc/sysctl.d/99-kubernetes-cri.conf

  action "完成k8s 内核修改" /bin/true
}

# 开启ipvs前提配置
sysctl.ipvs() {
  cat >/etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
EOF
  # 高版本的centos内核nf_conntrack_ipv4被nf_conntrack替换了
  chmod 755 /etc/sysconfig/modules/ipvs.modules
  bash /etc/sysconfig/modules/ipvs.modules
  lsmod | grep -e ip_vs -e nf_conntrack

  yum install -y ipset ipvsadm

}

#修改系统源为国内源
change.repos.ali() {
  msg "green" "修改系统源为国内源"

  reposType=$1

  if [ ! -d "/etc/yum.repos.d.initial.back" ]; then
    mkdir /etc/yum.repos.d.initial.back
  fi
  mv -f /etc/yum.repos.d/* /etc/yum.repos.d.initial.back

  if [ "${reposType}" = "local" ]; then

    cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[base]
name=CentOS-Base
baseurl=http://mirrors.ztoyc.zt/7/repo/base/
enabled=1

[updates]
name=CentOS-Updates
baseurl=http://mirrors.ztoyc.zt/7/repo/updates/
enabled=1

[extras]
name=CentOS-Extras
baseurl=http://mirrors.ztoyc.zt/7/repo/extras/
enabled=1

[epel]
name=CentOS-Epel
baseurl=http://mirrors.ztoyc.zt/7/repo/epel/
enabled=1

[docker-ce]
name=docker-ce
baseurl=http://mirrors.ztoyc.zt/7/repo/docker-ce-stable/
enabled=1

[kubernetes]
name=kubernetes
baseurl=http://mirrors.ztoyc.zt/7/repo/kubernetes/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF
  else

    curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

    sed -i 's@http://mirrors.cloud.aliyuncs.com@http://mirrors.aliyun.com@g' /etc/yum.repos.d/CentOS-Base.repo

    cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
  fi
  yum clean all

  yum makecache -y

  action "完成yum源修改" /bin/true

}

# 安装containerd
install.containerd() {
  msg "green" "安装containerd"

  yum install -y containerd.io
  if ! (type containerd >/dev/null 2>&1); then
    msg "red" "安装containerd 失败"
    action "安装containerd " /bin/false
    exit 1
  fi

  containerd config default >/etc/containerd/config.toml

  # 替换 pause 镜像
  sed -i "/sandbox_image/d" /etc/containerd/config.toml
  sed -i "/stats_collect_period/i\    sandbox_image = \"registry.aliyuncs.com/google_containers/pause:3.7\"" /etc/containerd/config.toml

  #sed -i "s@registry.k8s.io/pause:3.6@registry.aliyuncs.com/google_containers/pause:3.7@g" /etc/containerd/config.toml
  # systemd_cgroup = true 会导致 kubeadm pull image 失败，unknown service runtime.v1alpha2.ImageService
  # sed -i 's@systemd_cgroup \= false@systemd_cgroup \= true@' /etc/containerd/config.toml

  systemctl enable containerd
  systemctl restart containerd
  systemctl status containerd

  msg "green" "配置 crictl"

  cat <<EOF >/etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

  action "完成安装containerd" /bin/true

}

#安装kubectl、kubelet、kubeadm
install.k8s() {
  msg "green" "安装k8s命令工具..."

  yum install -y kubectl-${version} kubelet-${version} kubeadm-${version}

  systemctl enable kubelet
  systemctl start kubelet
  action "完成安装k8s组件" /bin/true
}

config.k8s() {
  msg "green" "配置k8s中..."
  if ! [ -d "$HOME/.kube" ]; then
    mkdir -p "$HOME/.kube"
  fi

  cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
  chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"
}

network.k8s() {
  msg "green" "安装calico网络.."
  kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
}

cluster-info.k8s() {
  kubectl cluster-info
}

#初始化k8s master
initial.k8s.master() {

  msg "green" "初始化k8s中..."
  k8sversion=$(kubeadm version | grep -Eo 'v[0-9].[0-9]{2}.[0-9]{1,2}')
  k8sApi=$(hostname -I | awk -F' ' '{print $1}')

  if kubeadm init \
    --apiserver-advertise-address="$k8sApi" \
    --apiserver-cert-extra-sans=127.0.0.1 \
    --image-repository=registry.aliyuncs.com/google_containers \
    --ignore-preflight-errors=all \
    --kubernetes-version="$k8sversion" \
    --v 5 \
    --service-cidr=10.10.0.0/16 \
    --pod-network-cidr=10.18.0.0/16; then

    # image-repository string      这个用于指定从什么位置来拉取镜像（1.13版本才有的），默认值是k8s.gcr.io，我们将其指定为国内镜像地址：registry.aliyuncs.com/google_containers
    # kubernetes-version string    指定kubenets版本号，默认值是stable-1，会导致从https://dl.k8s.io/release/stable-1.txt下载最新的版本号，我们可以将其指定为固定版本（v1.22.1）来跳过网络请求。
    # apiserver-advertise-address  指明用 Master 的哪个 interface 与 Cluster 的其他节点通信。如果 Master 有多个 interface，建议明确指定，如果不指定，kubeadm 会自动选择有默认网关的 interface。这里的ip为master节点ip，记得更换。
    # pod-network-cidr             指定 Pod 网络的范围。Kubernetes 支持多种网络方案，而且不同网络方案对  –pod-network-cidr有自己的要求，这里设置为10.244.0.0/16 是因为我们将使用 flannel 网络方案，必须设置成这个 CIDR。
    # control-plane-endpoint        cluster-endpoint 是映射到该 IP 的自定义 DNS 名称，这里配置hosts映射：192.168.0.113   cluster-endpoint。 这将允许你将 --control-plane-endpoint=cluster-endpoint 传递给 kubeadm init，并将相同的 DNS 名称传递给 kubeadm join。 稍后你可以修改 cluster-endpoint 以指向高可用性方案中的负载均衡器的地址
    # kubeadm  不支持将没有 --control-plane-endpoint 参数的单个控制平面集群转换为高可用性集群。

    config.k8s
    network.k8s
    cluster-info.k8s

    action "完成k8s初始化" /bin/true
  else
    action "k8s初始化失败" /bin/false
  fi
}

#初始化k8s node
initial.k8s.node() {

  msg "green" "初始化k8s node..."

  if [ "$($1)" ]; then
    action "完成k8s初始化" /bin/true
  else
    action "k8s初始化失败" /bin/false
  fi
}

main() {

  role=$(whiptail --title "初始化K8S" --menu "请您选择node的角色" 10 60 4 \
    "Master" "Master" \
    "Node" "Node" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 0 ]; then
    msg "green" "安装k8s ${version} ${role} ..."
  else
    echo "You chose Cancel."
    exit 1
  fi

  code=$(whiptail --title "初始化K8S" --inputbox "请将kubeadm join 填在输入框中" 10 60 3>&1 1>&2 2>&3)
  exitstatus=$?
  if ! [ $exitstatus -eq 0 ]; then
    echo "You chose Cancel."
    exit 1
  fi

  selinux.config
  swap.config
  sysctl.k8s
  sysctl.ipvs
  change.repos.ali local
  install.containerd
  install.k8s

  if [ "$role" = "Master" ]; then
    initial.k8s.master
  else
    initial.k8s.node "${code}"
  fi

}

main
