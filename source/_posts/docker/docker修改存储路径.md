---
title: docker 修改默认存储路径
date: 2021-12-06 10:34
categories:
- docker
tags:
- docker
---
  
  
摘要: docker 修改默认存储路径
<!-- more -->

### 查看当前docker的存储路径
```
docker info |grep Dir


Docker Root Dir: /var/lib/docker              ## docker默认的存储路径

```

### 关闭docker服务
```
systemctl stop docker            ## 关闭docker服务
systemctl status docker		       ## 查看docker服务状态
```

### 将原有数据迁移至新目录
```
mkdir /opt/docker -p
mv /var/lib/docker/* /opt/docker/
```

### 修改 docker.service 配置文件，使用 --graph 参数指定存储位置
```
vim /usr/lib/systemd/system/docker.service

ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --graph /opt/docker

```

### 重新加载配置文件
```
systemctl daemon-reload
```

### 启动docker服务
```
systemctl start docker
systemctl enable docker
systemctl status docker
```

### 查看修改是否成功
```
docker info | grep Dir

 Docker Root Dir: /data/service/docker                ## 查看修改成功
```




