---
title: centos7 基于python3环境安装ansible
date: 2021-11-26 17:28
categories:
- centos7
tags:
- ansible
---
  
  
摘要: desc
<!-- more -->

## python3 源码编译
```
# 编译环境准备
yum install gcc patch libffi-devel python-devel zlib-devel bzip2-devel openssl-devel \
ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel libpcap-devel xz-devel -y

# 下载python3源码
curl https://www.python.org/ftp/python/3.8.6/Python-3.8.6.tgz -o Python-3.8.6.tgz

# 解压
tar xvf Python-3.8.6.tgz

# 编译配置
cd Python-3.8.6
./configure --prefix=/usr/local/python38
# 开始编译
make -j4

# 安装编译文件
make install
```

## 安装ansible
```
/usr/local/python38/bin/pip3 install ansible -i https://mirrors.aliyun.com/pypi/simple
```

## 本机使用
```
# 添加软链
ln -s /usr/local/python38/bin/python3 /usr/bin/python3
ln -s /usr/local/python38/bin/ansible /usr/bin/ansible
ln -s /usr/local/python38/bin/ansible-playbook /usr/bin/ansible-playbook
```

## 打包离线使用
```
# 打包为压缩包
tar zcvf python38.tgz /usr/local/python38/

# 直接将压缩包在目标机解压，添加软链即可使用
tar xvf python38.tgz -C /
ln -s /usr/local/python38/bin/python3 /usr/bin/python3
ln -s /usr/local/python38/bin/ansible /usr/bin/ansible
ln -s /usr/local/python38/bin/ansible-playbook /usr/bin/ansible-playbook
```
