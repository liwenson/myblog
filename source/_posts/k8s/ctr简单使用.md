---
title: ctr简单使用
date: 2022-11-01 17:26
categories:
- k8s
tags:
- ctr
- containerd
---
  
  
摘要: desc
<!-- more -->

## ctr使用

### 查询本地镜像

ctr 需要指定命名空间,k8s 默认使用 k8s.io

```bash
ctr image ls

# k8s

ctr -n k8s.io image ls
```

### 下载镜像

ctr 不支持http,必须使用https, 使用http需要添加 --plain-http 参数

```bash
ctr images pull --plain-http --user admin:123456 192.168.20.11/source/coredns:1.2.0
```

### 镜像导出

```bash
ctr image export   coredns.tar  192.168.20.11/source/coredns:1.2.0
```

### 镜像导入

```bash
ctr image import coredns.tar
```

### 镜像打tag

```bash
ctr image tag 192.168.20.11/source/coredns:1.2.0 192.168.20.11/test/coredns:1.2.0
```

### 推送镜像

```bash
ctr  image push --plain-http --user admin:123456  192.168.20.11/test/coredns:1.2.0
```



