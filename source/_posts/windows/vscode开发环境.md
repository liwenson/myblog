---
title: vscode开发环境
date: 2021-11-03 16:07
categories:
- windows
tags:
- vscode
---
  
  
摘要: vscode远程开发环境
<!-- more -->


## 安装vscode


## 安装 Docker Desktop

官网 | https://www.docker.com/

下载地址: https://www.docker.com/get-started


## 安装vscode插件 Remote Development

这其实是插件集合, 包括了 Remote-SSH , Remote-Containers, Remote-WSL 等

[Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)

- [Remote-SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)

- [Remote-Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

- [Remote-WSL](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl)


比较
||Remote - SSH|Remote - Containers|Remote - WSL| 
|---|---|---|---|
|Remote Env|Server、VM、Contaioner|Container|Windows OS| 
|Description|可以在性能更高、更专业的资源上进行开发，在不通的远程开发环境之间快速切换，不会影响本地的环境|通过容器隔离环境，可以在不同的开发环境之间快速切换，不会影响本地环境保持环境的一致性，而且便于分发|可以在windows系统下的Linux环境中进行开发|
|Scenarios|编写、调试和运行在远程环境的应用程序源代码存放在远程环境|源代码存放在本地，可以连接本地或远程的容器|在windows上编写、调试和运行基于Linux的应用程序，源代码存放在本地|
|Preparation|配置本地SSH客户端和远程主机SSH服务|本地安装配置Docker，如果容器是运行在远程主机，本地只需要docker client|本地windows系统安装配置WSL|



## Remote SSH 
远程主机已安装ssh-server
本地主机已安装ssh-client

打开 远程窗口 面板，在左下角 >\<

输入 Connect to Host 回车 
选择 + Add New SSH Host 
输入 ssh root@172.16.100.1   输入远程主机ssh 地址
添加完成

下次可以直接打开 远程窗口 输入 Connect to Host 回车 ，找到添加的记录就能登陆了



给远程环境安装插件，对本机的VS Code没有影响。
插件在远端提供功能，比如代码审查、自动补齐等等，而这所有的一切就像在本地操作一样，对文件的更改也是直接操作的远程环境中的文件。

## Remote Container

https://www.cnblogs.com/anliven/p/13296414.html

