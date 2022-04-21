---
title: 解决国外镜像仓库下载失败问题
date: 2022-04-15 15:05
categories:
- k8s
tags:
- k8s
---
  
  
摘要: 解决国外镜像仓库下载失败问题
<!-- more -->

## 现成的镜像代理仓库

### k8s.gcr.io

这是 gcr.io/google-containers 的仓库，使用阿里云镜像

```bash
docker pull k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.3.0

# 换成

docker pull registry.aliyuncs.com/google_containers/csi-node-driver-registrar:v2.3.0
```

也可以使用 lank8s.cn，他们的对应关系 k8s.gcr.io –> lank8s.cn，gcr.io –> gcr.lank8s.cn

```bash
docker pull k8s.gcr.io/sig-storage/csi-node-driver-registrar:v2.3.0

# 换成

docker pull lank8s.cn/sig-storage/csi-node-driver-registrar:v2.3.0

```

### quay.io

这是Red Hat运营的镜像库，虽然没有被墙，但下载还是比较慢，可以使用中科大镜像

```bash
docker image pull quay.io/kubevirt/virt-api:v0.45.0

# 换成

docker pull quay.mirrors.ustc.edu.cn/kubevirt/virt-api:v0.45.0
```

## 使用代理

创建配置目录

```bash
mkdir /etc/systemd/system/docker.service.d
```

添加文件

```bash
vim /etc/systemd/system/docker.service.d/http-proxy.conf

[Service]
Environment="HTTP_PROXY=socks5://10.200.92.12:7890/"
Environment="NO_PROXY=reg.ztoyc.com,10.10.10.10"
```

需要 dockerd 绕过代理服务器直连，配置 NO_PROXY 参数,多个 NO_PROXY 变量的值用逗号分隔

```bash
systemctl daemon-reload

systemctl restart docker
```

检查

```bash
systemctl show --property=Environment docker

Environment=HTTP_PROXY=socks5://10.200.92.12:7890/ NO_PROXY=reg.ztoyc.com,10.10.10.10
```

```bash
docker info | grep Proxy
 HTTP Proxy: socks5://10.200.92.12:7890/
 No Proxy: reg.ztoyc.com,10.10.10.10

```
