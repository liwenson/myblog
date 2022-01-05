---
title: docker-desktop修改资源路径
date: 2021-12-06 10:19
categories:
- docker
tags:
- docker
---
  
  
摘要:  docker-desktop修改资源路径
Docker是一个非常好用的容器引擎, 使我们部署环境速度大幅度提升。但是windows版本的docker-desktop默认安装路径是C盘，这时候就有一个非常让人头疼的问题 
- C盘储存空间严重不足
<!-- more -->
## 前言
原缓存路径
```
C:\Users${用户文件}\AppData\Local\Docker
```

## 方案一
Docker-desktop在初始化的时候会创建两个wsl子系统，这两个系统文件会默认保存在上述缓存路径下
```
wsl -l -v --all

  NAME                   STATE           VERSION
* docker-desktop-data    Stopped         2
  docker-desktop         Stopped         2
```

- docker-desktop：   保存的是程序,占用空间很小,可以不迁移
- docker-desktop-data: 保存的镜像

**在关闭docker-desktop的情况下再进行操作。**

### 通过wsl命令将这两个子系统进行迁移
#### 备份命令
```
wsl --export docker-desktop docker-desktop.tar
wsl --export docker-desktop-data docker-desktop-data.tar
```

#### 注销命令
```
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data
```

#### 导入命令
```
wsl --import docker-desktop-data D:\docker\docker-desktop-data docker-desktop-data.tar  --version 2
wsl --import docker-desktop D:\docker\docker-desktop docker-desktop.tar  --version 2
```
查看
```
wsl -l -v --all

  NAME                   STATE           VERSION
* docker-desktop-data    Stopped         2
  docker-desktop         Stopped         2
```

**注意: 划重点, 两个子系统文件使用的目录限制不能为同一个目录.**

完成以上操作启动docker-desktop下载镜像文件就不会保存到C盘啦。


## 方案二 (未验证)


对docker默认缓存路径创建联接指向别的磁盘文件。

首先关闭docker-desktop以及所有运行的镜像文件

将C:\Users${用户文件}\AppData\Local\Docker文件移动到需要的磁盘里
使用命令设置联接

联接建立成功启动即可
```
cmd /c mklink /J Docker D:\Repository\Docker
```
**注意: 是在原缓存文件Docker的根目录下通过powershell执行命令，由于powershell不支持mklink的指令，所以需要在前面增加 cmd /c.**

```
PS C:\Users\li\AppData\Local> cmd /c mklink /J Docker D:\Repository\Docker
为 Docker <<===>> D:\Repository\Docker 创建的联接

```


