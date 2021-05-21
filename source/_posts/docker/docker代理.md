---
title: docker配置代理
date: 2021-05-08 14:15
categories:
- docker
tags:
- docker
---
  
  
摘要: docker 配置代理
<!-- more -->


## 配置代理服务器
创建或修改 /etc/docker/daemon.json：
```
{
    "registry-mirrors": [
        "https://1nj0zren.mirror.aliyuncs.com",
        "https://docker.mirrors.ustc.edu.cn",
        "http://f1361db2.m.daocloud.io",
        "https://registry.docker-cn.com"
    ]
}
```

加载配置：
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

检查代理服务器是否生效
命令行执行 `docker info`，查看配置是否已经生效。
可以看到日志的最后部分有下面配置，说明就已经生效了。

```
Registry Mirrors:
 https://1nj0zren.mirror.aliyuncs.com/
 https://docker.mirrors.ustc.edu.cn/
 http://f1361db2.m.daocloud.io/
 https://registry.docker-cn.com/
Live Restore Enabled: true
```


Docker Hub 镜像加速器列表

|镜像加速器|镜像加速器地址|
|---|---|
|Docker中国|	https://registry.docker-cn.com|
|DaoCloud	|http://f1361db2.m.daocloud.io（可登录）|
|Azure |https://dockerhub.azk8s.cn|
|中科大 |https://docker.mirrors.ustc.edu.cn |
|阿里云	|https://<your_code>.mirror.aliyuncs.com（需登录）|
|七牛云	|https://reg-mirror.qiniu.com|
|网易云	|https://hub-mirror.c.163.com|
|腾讯云	|https://mirror.ccs.tencentyun.com|
