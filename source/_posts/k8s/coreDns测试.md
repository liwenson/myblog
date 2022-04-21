---
title: k8s中dns测试
date: 2022-04-13 10:06
categories:
- k8s
tags:
- coreDns
---
  
  
摘要: k8s中dns测试
<!-- more -->

## 部署调试工具

```bash
vim ndsutils.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dnsutils
spec:
  containers:
  - name: dnsutils
    image: mydlqclub/dnsutils:1.3
    imagePullPolicy: IfNotPresent
    command: ["sleep","3600"]
```

## 问题分析

进入 DNS 工具 Pod 的命令行

```bash
kubectl exec -it dnsutils sh
```

通过 Ping 和 Nsloopup 命令测试

```bash
# Ping 集群外部，例如这里 ping 一下百度

$ ping www.baidu.com
ping: bad address 'www.baidu.com'

# Ping 集群内部 kube-apiserver 的 Service 地址

$ ping kubernetes.default
ping: bad address 'kubernetes.default'

# 使用 nslookup 命令查询域名信息

$ nslookup kubernetes.default
;; connection timed out; no servers could be reached

# 直接 Ping 集群内部 kube-apiserver 的 IP 地址

$ ping 10.96.0.1
PING 10.96.0.1 (10.96.0.1): 56 data bytes
64 bytes from 10.96.0.1: seq=0 ttl=64 time=0.096 ms
64 bytes from 10.96.0.1: seq=1 ttl=64 time=0.050 ms
64 bytes from 10.96.0.1: seq=2 ttl=64 time=0.068 ms

# 退出 dnsutils Pod 命令行

$ exit

```