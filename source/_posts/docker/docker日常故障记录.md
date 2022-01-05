---
title: docker碰到的故障
date: 2021-12-21 15:42
categories:
- docker
tags:
- docker
---
  
  
摘要: docker 故障处理
<!-- more -->

## docker 容器无响应
### 症状
创建容器卡住，状态一直处于 Create，所有操作都没有响应(docker logs, docker stop ,docker restart， docker inspect，docker run)

### 尝试
docker stop containerID 命令 卡住，无响应 尝试失败！
docker kill containerID 命令 卡住，无响应 尝试失败！
docker container prune  尝试失败！
ps -ef | grep containerID
kill -9 containerID     能杀掉，但是还是不能创建

### 处理
重启 docker 服务 之后正常


## docker 容器无响应
### 症状
容器状态正常，但是所有操作都没有响应(docker logs, docker stop ,docker restart， docker inspect，docker run)

### 尝试
docker stop containerID 命令 卡住，无响应 尝试失败！
docker kill containerID 命令 卡住，无响应 尝试失败！

### 处理
ps -ef | grep java
kill -9 PID 

重新部署容器，正常
