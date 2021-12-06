---
title: ansible模块开发
date: 2021-11-03 10:20
categories:
- ansible
tags:
- ansible
---
  
  
摘要: ansible模块开发
<!-- more -->


# 介绍

Ansible 开发分为两大模块，一是modules，而是plugins。

首先，要记住这两部分内容在哪个地方执行？

- modules 文件被传送到远端主机并执行。
- plugins 是在ansible服务器上执行的。

再者是执行顺序？  `plugins` 先于 `modules` 执行。


然后大家明确这两部分内容是干啥用的？

- modules 是ansible的核心内容，它使playbook变得更加简单明了，一个task就是完成某一项功能。ansible模块是被传送到远程主机上运行的。所以它们可以用远程主机可以执行的任何语言编写modules。
- plugins 是在ansible主机上执行的，用来辅助modules做一些操作。比如连接远程主机，拷贝文件到远程主机之类的。

plugins存放位置

- ANSIBLE_plugin_type_PLUGINS 环境变量值指定的目录，其中plugin_type是指插件类型，如ANSIBLE_INVENTORY_PLUGINS
- ~/.ansible/plugins/目录下的
- 当前剧本目录下的callback_plugins
- role目录下的callback_plugins

modules存放位置

- ANSIBLE_LIBRARY环境变量值指定的目录
- ~/.ansible/plugins/modules/ 当前用户目录下
- /usr/share/ansible/plugins/modules/ 系统自定义目录下
- 当前剧本目录下的library
- role目录下的library
