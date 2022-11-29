---
title: harbor搭建helm仓库
date: 2022-05-05 17:35
categories:
- docker
tags:
- harbor
---
  
  
摘要: harbor搭建helm仓库
<!-- more -->

## 部署harbor

略

启用Harbor的Chart仓库服务

```bash
./install.sh --with-chartmuseum
```

启用后，默认项目就带有helm charts功能了。

启动harbor

创建一个 myrepo 项目

## 安装helm

```bash
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
```

```bash
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  6666  100  6666    0     0   7177      0 --:--:-- --:--:-- --:--:--  7175
Downloading https://get.helm.sh/helm-v2.17.0-linux-amd64.tar.gz
Preparing to install helm and tiller into /usr/local/bin
helm installed into /usr/local/bin/helm
tiller installed into /usr/local/bin/tiller
helm not found. Is /usr/local/bin on your $PATH?
Failed to install helm
 For support, go to https://github.com/helm/helm.
```

软链接

```bash
ln -s /usr/local/bin/helm /usr/bin/helm
```

初始化helm

```bash
helm init
```

## 安装helm pull 插件

```bash
helm plugin install https://github.com/chartmuseum/helm-push
Downloading and installing helm-push v0.10.2 ...
https://github.com/chartmuseum/helm-push/releases/download/v0.10.2/helm-push_0.10.2_linux_amd64.tar.gz
Installed plugin: cm-push
```

```bash
helm plugin list
```

## 添加harbor 仓库

```bash
helm repo add --username=admin --password=Harbor12345 myrepo http://192.168.75.100:10000/chartrepo/myrepo
```

查看仓库

```bash
helm repo list

```

## helm pull 使用

### 创建app

```bash
helm create app
```

### 上传app

```bash
helm cm-push app myrepo
```
