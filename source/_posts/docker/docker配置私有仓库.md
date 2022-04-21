---
title: docker 配置私有仓库
date: 2022-04-13 14:18
categories:
- docker
tags:
- docker
---
  
  
摘要: docker配置私有仓库
<!-- more -->

## 方案一

测试没有通过

```bash
vim /etc/docker/daemon.json

{
  "registry-mirrors": ["https://1111.aliyuncs.com"],
  "insecure-registries": ["1.1.1.1:80","abc.test.com"]
}
```

## 方案二

在 service 文件中添加参数  --insecure-registry=abc.test.com

```bash
vim /usr/lib/systemd/system/docker.service

#约 13 行
ExecStart=/usr/bin/dockerd -H fd:// --insecure-registry=reg.ztoyc.com --containerd=/run/containerd/containerd.sock
```

测试有效，不能和方案一混用

## 代理配置

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
