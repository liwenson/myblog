!---
title: harbor版本升级
date: 2022-09-16 14:09
categories:
- docker
tags:
- harbor
---
  
  
摘要: harbor 版本从v2.3.3 升级到v2.6.0
<!-- more -->

## 准备v2.6.0 的离线安装包

```bash
wget https://github.com/goharbor/harbor/releases/download/v2.6.0/harbor-offline-installer-v2.6.0.tgz
```

使用docker pull 获取组件镜像

```bash
# 将harbor使用v2.3.3的镜像获取，拼接出 docker pull 的镜像
docker images | grep "goharbor" |grep "v2.3.3" | awk '{print "docker pull "$1":v2.6.0"}'
```

## 备份

将harbor 停机，进行数据文件备份

```bash
cd /opt/harbor
docker-compose down

cd ..
mv harbor harborBack
```

如果镜像比较多可以只备份 harbor/data/database 数据库文件

## 导入镜像

通过docker pull 手动操作过，可以跳过

```bash
docker image load -i harbor/harbor.v2.6.0.tar.gz
```

## 升级harbor.yml

将备份的harbor 中的配置文件，复制到新版的目录中,在执行升级

```bash
cd harbor
cp /opt/harborBack/harbor.yml .
cd /
docker run -it --rm -v /:/hostfs goharbor/prepare:v2.6.0 migrate -i /opt/harbor/harbor.yml
```

## 安装新版

```bash
cd harbor
./install.sh
```
