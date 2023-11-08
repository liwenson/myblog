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

### 命令对比

|命令 | docker | ctr（containerd）| crictl（kubernetes）|
|---|---|---|---|
|查看运行的容器|docker ps|ctr task ls/ctr container ls|crictl ps|
|查看镜像 | docker images | ctr image ls | crictl images |
|查看容器日志 | docker logs | 无 | crictl logs|
|查看容器数据信息 | docker inspect | ctr container info | crictl inspect|
|查看容器资源 | docker stats | 无 crictl stats |
|启动/关闭已有的容器 | docker start/stop | ctr task start/kill | crictl start/stop | 
|运行一个新的容器 | docker run | ctr run | 无（最小单元为 pod）|
|打标签 | docker tag | ctr image tag | 无|
|创建一个新的容器 | docker create | ctr container create | crictl create|
|导入镜像 | docker load | ctr image import | 无 |
|导出镜像 | docker save | ctr image export |无 |
|删除容器 | docker rm | ctr container rm | crictl rm |
|删除镜像 | docker rmi | ctr image rm | crictl rmi |
|拉取镜像 | docker pull | ctr image pull | ctictl pull |
|推送镜像 | docker push | ctr image push | 无 |
|登录或在容器内部执行命令 | docker exec | 无 |crictl exec |
|清空不用的容器 | docker image prune | 无 |crictl rmi --prune |





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



