---
title: centos7安装sentry
date: 2021-06-21 09:39
categories:
- centos
tags:
- sentry
---
	
	
摘要: cenos7安装sentry
<!-- more -->


Sentry 的管理后台是基于 Python Django 开发的。这个管理后台由背后的 Postgres 数据库（管理后台默认的数据库，后续会以 Postgres 代指管理后台数据库并进行分享）、ClickHouse（存数据特征的数据库）、relay、kafka、redis 等一些基础服务或由 Sentry 官方维护的总共 23 个服务支撑运行。可见的是，如果独立的部署和维护这 23 个服务将是异常复杂和困难的。幸运的是，官方提供了基于 docker 镜像的一键部署实现 [getsentry/onpremise](https://github.com/getsentry/onpremise)。

这种部署方式依赖于 Docker 19.03.6+ 和 Compose 1.24.1+

## 准备工作
### 安装docker 
Docker 是可以用来构建和容器化应用的开源容器化技术。

##### 安装依赖
```
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

##### 添加docker下载仓库
```
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

##### 安装docker-ce
```
sudo yum install docker-ce
```

##### 启动docker-ce
```
sudo systemctl start docker
```

##### 验证
```
sudo docker --version
sudo docker run hello-world
```


### 安装docker-compose 
Compose 是用于配置和运行多 Docker 应用的工具，可以通过一个配置文件配置应用的所有服务，并一键创建和运行这些服务。

```
curl -L https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

## github

sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

docker-compose --version
```

#### docker 镜像加速

方式一： 在后续部署的过程中，需要拉取大量镜像，官方源拉取较慢，可以修改 docker 镜像源，修改或生成 /etc/docker/daemon.json 文件：
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

方式二：配置docker代理
```
mkdir -p /etc/systemd/system/docker.service.d
vim /etc/systemd/system/docker.service.d/http-proxy.conf

[Service]
Environment="HTTP_PROXY=socket5://172.16.100.86:7890"
Environment="HTTPS_PROXY=socket5://172.16.100.86:7890"
Environment="NO_PROXY=localhost,127.0.0.1,docker-registry.example.com,.corp"

```

然后重新加载配置，并重启 docker 服务：
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 一键部署


在 onpremise 的根路径下有一个 install.sh 文件，只需要执行此脚本即可完成快速部署，脚本运行的过程中，大致会经历以下步骤：
```
1、环境检查
2、生成服务配置
3、docker volume 数据卷创建（可理解为 docker 运行的应用的数据存储路径的创建）
4、拉取和升级基础镜像
5、构建镜像
6、服务初始化
7、设置管理员账号（如果跳过此步，可手动创建）
```




