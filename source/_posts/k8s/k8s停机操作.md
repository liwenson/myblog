---
title: k8s 停机操作
date: 2022-02-17 13:54
categories:
- k8s
tags:
- k8s
---
  
  
摘要: k8s 停机操作
<!-- more -->

## 关机过程

### node节点

[root@dn02 ~]# systemctl stop kube-proxy
[root@dn02 ~]# systemctl stop kubelet

### master

[root@dn01 ~]# systemctl stop kube-scheduler
[root@dn01 ~]# systemctl stop kube-controller-manager
[root@dn01 ~]# systemctl stop kube-apiserver.service

### 关闭 node节点的flanneld 服务

[root@dn02 ~]# systemctl stop flanneld

### 全部节点关闭etcd

[root@dn0X~]# systemctl stop etcd

[root@dn0X ~]# systemctl stop docker

### 全部关机

[root@dn01 ~]# init 0


## 开机过程

systemctl start etcd  三节点

systemctl start flanneld （node 节点）

systemctl start kube-apiserver.service  (默认设置了开机启动， master 节点)

systemctl start kube-scheduler （默认设置了开机启动， master 节点）

systemctl start kube-controller-manager （默认设置了开机启动， master 节点）

systemctl start kubelet（node 节点）

systemctl start kube-proxy（node 节点）


systemctl start flanneld （node 节点）

systemctl restart kube-apiserver.service  (默认设置了开机启动， master 节点)

systemctl restart kube-scheduler （默认设置了开机启动， master 节点）

systemctl restart kube-controller-manager （默认设置了开机启动， master 节点）

systemctl restart kubelet（node 节点）

systemctl restart kube-proxy（node 节点）
