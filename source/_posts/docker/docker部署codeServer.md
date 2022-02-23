---
title: docker 部署code-server
date: 2021-12-31 17:15
categories:
- docker
tags:
- code
---
  
  
摘要: code-server
<!-- more -->


## 安装docker
安装环境为centos8


```
# 获取阿里云yum镜像文件
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-8.repo


# 非阿里云主机需要替换地址
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo

# 重建 yun cache
yum clean all
yum makecache
# 使用yum升级系统
yum update  --nobest

#删除旧的docker
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine -y

# 安装最新版的containerd.io
dnf install https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/nightly/Packages/containerd.io-1.2.6-3.3.el7.x86_64.rpm

#安装Yum源管理工具
yum install -y yum-utils device-mapper-persistent-data lvm2

#安装阿里云的docker-ce源
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache

#安装docker-ce

yum install docker-ce docker-ce-cli

#配置docker 镜像
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://heusyzko.mirror.aliyuncs.com"],
  "log-driver":"json-file",
  "log-opts": {"max-size":"500m", "max-file":"3"}
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

```

## 安装 docker-compose
```
curl -L https://get.daocloud.io/docker/compose/releases/download/1.26.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

## 准备vs的settings.json配置文件
vi settings.json
```
{
    // Nomal
    "editor.fontSize": 18,
    "workbench.iconTheme": "vscode-icons",
    "vsicons.dontShowNewVersionMessage": true,
    "editor.minimap.enabled": true,
    "workbench.colorTheme": "Visual Studio Light",
    "workbench.startupEditor": "newUntitledFile",
    // 保存格式化
    "files.autoSave": "onFocusChange",
    "editor.formatOnPaste": true,
    "editor.formatOnType": true,
    // Env
    "java.home": "/usr/local/jdk1.8.0_261",
    "maven.executable.path": "/usr/local/apache-maven-3.6.0/bin/mvn",
    "java.configuration.maven.userSettings": "/usr/local/apache-maven-3.6.0/conf/settings.xml",
    "maven.terminal.customEnv": [
        {
            "environmentVariable": "JAVA_HOME",
            "value": "/usr/local/jdk1.8.0_261"
        }
    ],
    "python.formatting.provider": "yapf",
    "python.autoComplete.addBrackets": true,
    "python.jediEnabled": false,
    "python.linting.pylintEnabled": true,
    // exclude file
    "files.exclude": {
        "**/.classpath": true,
        "**/.project": true,
        "**/.settings": true,
        "**/.factorypath": true,
        "**/.vscode": true,
        "**/.empty": true,
    },
    // code-runner
    "code-runner.clearPreviousOutput": true,
    "code-runner.runInTerminal": false,
    // 执行文件的脚本，可以使用绝对路径
    "code-runner.executorMap": {
        "python": "/usr/local/anaconda3/python3",
        "java": "cd $dir && javac $fileName && java $fileNameWithoutExt",
    },
}

```

## 编辑Dockerfile文件

vs code的插件建议自行在官方市场下载后,放到extensions目录。
下载地址：
https://marketplace.visualstudio.com/

#### 支持java 环境的镜像
```
FROM codercom/code-server:latest
# COPY JDK和MAVEN
COPY jdk1.8.0_261 /usr/local/jdk1.8.0_261/
COPY apache-maven-3.6.3 /usr/local/apache-maven-3.6.3/

# code-server配置文件 插件
COPY extensions /root/.local/share/code-server/extensions/
COPY settings.json /root/.local/share/code-server/User/

# Env
ENV JAVA_HOME=/usr/local/jdk1.8.0_261 \
    JRE_HOME=/usr/local/jdk1.8.0_261/jre \
    PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin \
    CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib \
    MAVEN_HOME=/usr/local/apache-maven-3.6.3

ENV PATH=$MAVEN_HOME/bin:$PATH

WORKDIR /home/coder/project
# 容器启动code-server：指定插件目录，指定中文，指定免密登录
ENTRYPOINT ["code-server","--locale","zh-cn","--host","0.0.0.0","--port","8080", "--user-data-dir", "/home/coder","--cert",""]

```

#### 支持python3 环境的镜像
```
FROM codercom/code-server:latest
RUN sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free' >> /home/coder/sources.list \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free' >> /home/coder/sources.list \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free' >> /home/coder/sources.list \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free' >> /home/coder/sources.list \
    && sudo mv /home/coder/sources.list /etc/apt/ \
    && sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y fonts-powerline python3 python3-pip vim \
    && sudo apt-get clean
```

## C/Cpp
```
FROM codercom/code-server
RUN sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free' >> /home/coder/sources.list \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free' >> /home/coder/sources.list \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free' >> /home/coder/sources.list \
    && echo 'deb https://mirrors.tuna.tsinghua.edu.cn/debian-security buster/updates main contrib non-free' >> /home/coder/sources.list \
    && sudo mv /home/coder/sources.list /etc/apt/ \
    && sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y fonts-powerline build-essential gdb vim \
    && sudo apt-get clean
```


## 构建镜像
```
docker build -t boshine/code-server:latest --rm=true .
```

## 编辑docker-compose

    如果团队多人一起协同开发，建议每个人部署一个code-server容器，实现环境隔离。
    配合github/gitee/gitlab等代码管理服务器使用。

```
version: "3"

services:
  luocoder:
    container_name: luocoder
    image: boshine/code-server
    links:
      - db
    depends_on:
      - db
    ports:
      - "8080:8080"
      - "8088:8088"
    volumes:
      - "/root/code-server:/home/"
      - "/root/code-server/root:/root"
      - "/root/code-server/tmp:/tmp"
    environment:
      PASSWORD: 12345678
    restart: always
    privileged: true
    user: root

  db:
    container_name: mysql
    image: mysql:5.7
    ports:
      - "3306:3306"
    volumes:
      - "/root/mysql/data:/var/lib/mysql"
      - "/root/mysql/conf:/etc/mysql"
      - "/root/mysql/logs:/var/log/mysql"
    command: [
            '--character-set-server=utf8mb4',
            '--collation-server=utf8mb4_unicode_ci',
            '--max_connections=3000'
    ]
    environment:
      MYSQL_ROOT_PASSWORD: 12345678
    restart: always
    privileged: true
    user: root
```

## 运行
使用docker-compose运行coder容
```
docker-compose up -d
```



## ssl 支持
Code Server是支持ssl证书的，参考其文档。因为我使用Code Server容器的话，所以直接在Docker运行配置中添加对应参数即可。运行命令如下
```
docker run -dit --cap-add SYS_PTRACE --name 命名运行的容器名称 -p 0.0.0.0:8100:8080 \
  -v /宿主机中的创建的home文件夹路径:/home/coder \
  -v /宿主机中证书路径/cert.pem:/容器中证书路径/cert.pem \
  -v /宿主机中公钥路径/key.pem:/容器中公钥路径/key.pem \
  -u "$(id -u):$(id -g)" \
  -e PASSWORD=设置的登录密码 \
  构建的镜像名字 --cert /容器中证书路径/cert.pem --cert-key /容器中公钥路径/key.pem
```


