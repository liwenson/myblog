---
title: minio 集群搭建
date: 2021-03-21 16:25
categories:
- minio
tags:
- minio
---
  
  
摘要: 使用docker 搭建Minio集群
<!-- more -->

## 注意点
分布式Minio里的节点时间差不能超过15分钟，你可以使用NTP 来保证时间一致。
使用docker部署时，如果要使用主机的ip传入host名字，建议使用–net=host该情况下相当于将docker作为一个进程管理工具(类似systemctl)。
Minio集群部署挂载的目录必须为空目录，且集群的driver组成必须为如下值:4, 6, 8, 10, 12, 14, 16当driver挂掉时，只需保留N/2的节点就能保证只读。如：8节点集群，4个节点下线后集群仍然可读。但在启动数量少于5个节点之前，该集群无法进行写操作。
driver定义如下：每台开发机均为一个driver。可配置一台服务器可以通过挂载多个不同阵列增加driver来保证存储可用性。
集群需要保证ak/sk一致。


## 执行

在四台机器上分别上执行run_minio_node.sh
```
#!/bin/bash
# minio node 重启脚本 
access_port=9000       #启动监听的端口
role=cluster           #备注是集群还是单机 cluster或者Single
minio_ak=amaocl
minio_sk=amaocl@123
data_path=/data/minio/data
ip_list=(xxx,xxx,xxx,xxx)    #添加ip地址

minio_node_cluster=" "
for host in ${ip_list[@]} do
  info="http://$host:${access_port}${data_path}"
  minio_node_cluster="$minio_node_cluster $info"
done

function restart_minio_node(){
  container_name=minio-${role}-${access_port}
  docker kill $container_name || echo "ok"
  docker rm $container_name || echo "ok"
  docker run --name ${container_name} -d --net=host --restart=always -e "MINIO_ACCESS_KEY=${minio_ak}" -e "MINIO_SECRET_KEY=${minio_sk}" -v ${data_path}:/data minio/minio server ${minio_node_cluster}
}

restart_minio_node
```