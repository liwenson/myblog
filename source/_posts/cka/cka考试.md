---
title: cka考试文档
date: 2021-10-27 15:02
categories:
- cka
tags:
- k8s
- cka
---
	
	
摘要: cka考试文档
<!-- more -->

CKA 全称是 Certificated Kubernetes Administrator，也就是官方认证的 Kubernetes 管理员，由 Kubernetes 的管理机构 CNCF 授权。对于想做 Kubernetes 运维类工作的朋友，拿到 CKA 应该算是除了相关工作经验外，最有力的能力背书了。对于想做 Kubernetes 开发类工作的朋友，虽然不直接相关，但也是一个很好的入门方式。

## 报名
#### 形式
首先要说明的是 CKA 报名仅仅包含的是考试的费用，培训并不在其中，需要自行备考，虽然 CNCF 有对应的 CKA 备考培训，但是要单独收费。

CKA 的报名地址是： https://www.cncf.io/certification/cka/
培训的报名地址是： https://www.cncf.io/certification/training/

可以提供九折优惠 https://www.goodshop.com/coupons/linuxfoundation.org

#### 中文名字的麻烦
国内报考 CKA 有一点需要特别注意，CKA 的考试机构要求注册的用户姓名必须是拉丁字母，而且必须和 ID 上的一致（可以理解，不然怎么知道是一个人），中文显然不满足。如果有护照，那就方便了，直接可以用，没有的话，就要想办法做公证，我就是到当地的公证处做的身份证公证。

##  备考
#### 备考教程
作者将考试大纲对应的知识点，和有价值的参考资料汇总到了一起在 github 上的  https://github.com/walidshaari/Kubernetes-Certified-Administrator

#### 理论学习

Kubernetes指南（博客地址），可下载电子版的pdf。

两份指南学习时应侧重于Kubernetes自身框架以及概念的学习，部分非Kubernetes核心概念的知识点可粗略学习，例如《Kubernetes权威指南》中有关Kubernetes开发与Kubernetes源码的学习，在此可不作为重点。

在此阶段可通过Kubeadm等K8S搭建工具快速搭建一个K8S环境来熟悉和认识Kubernetes相关概念以及知识点。


#### 环境

有两个白嫖的方法

一 、  [play with kubernetes](https://labs.play-with-k8s.com/)

首先没有在自己的机器上部署k8s集群，而是选择了 [play with kubernetes](https://labs.play-with-k8s.com/)，线上的，不占用本机资源，而且相对于本机来说，线上的很容易部署。

play with kubernetes 使用参考 https://blog.csdn.net/Penguin_zlh/article/details/116303993


https://killercoda.com/playgrounds/scenario/kubernetes

https://killercoda.com/playgrounds

官方环境 https://killer.sh , 通过邮件登录



二、 部署
首先练习手动部署一套Kubernetes环境。不借助任何K8S的快速安装工具，通过手工部署K8S，能够更好的理解和熟悉K8S的各个组件和整体架构。

下面推荐一个手动部署教程：

[和我一步步部署 kubernetes 集群 git](https://github.com/opsnull/follow-me-install-kubernetes-cluster)

[和我一步步部署 kubernetes 集群 blog](https://k8s-install.opsnull.com/)


```
# 配置国内软件源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
sudo sed -i "s@http://.*archive.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
sudo sed -i "s@http://.*security.ubuntu.com@http://repo.huaweicloud.com@g" /etc/apt/sources.list
sudo apt-get update
# 部署 k8s
export release=3.2.0
wget https://github.com/easzlab/kubeasz/releases/download/${release}/ezdown
chmod +x ./ezdown
./ezdown -D
./ezdown -S
docker exec -it kubeasz ezctl start-aio
```

