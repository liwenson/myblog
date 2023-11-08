---
title: jenkins动态agent
date: 2023-03-31 10:55
categories:
- Jenkins
tags:
- agent
---
  
  
摘要: desc
<!-- more -->

## master安装jenkins

jenkins [rpm下载地址](https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/)

```
yum install jenkins-2.289.3-1.1.noarch.rpm -y
```

### 插件

docker

swarm-client

git Parameter

Docker Pipeline

docker-build-step

ansiColor

build user varsVersion

Groovy

Groovy Postbuild

略

### 安装docker

### 安装git

在构建代码是会使用jenkins触发docker启用一个jenkins slave 来构建代码

## slave


### 安装docker

### 安装nvm 用于维护node版本


### 启动swarm client

获取 swarm-client.jar

curl -O ${JENKINS_URL}/swarm/swarm-client.jar


启动脚本

根据情况调整参数

```bash
#!/bin/sh

set -e

JenkinsUser="60000000001"
JenkinsToken="11b2875665a7a38797ef01fba8e41aabd2"
JenkinsUrl="http://10.200.192.68:8080"
JenkinsAgentName="swarm-agen"

getPid() {
	pid=$(ps -ef | grep java | grep -v grep | grep "swarm-client.jar" | awk '{print $2}')
	echo $pid
}

start() {
	pid=$(getPid)
	if [ -n "$pid" ]; then
		echo "程序已经在运行: $pid"
		exit 1
	fi

	nohup java -jar $(pwd)/swarm-client.jar -username $JenkinsUser -password $JenkinsToken -master $JenkinsUrl -name $JenkinsAgentName >/dev/null 2>&1 &
}

stop() {
	pid1=$(getPid)
	if [ ! -n "$pid1" ]; then
		echo "程序已停止运行: $pid1"
	else
		kill -9 $pid1
	fi

	pid2=$(getPid)
	if [ ! -n "$pid2" ]; then
		echo "程序已停止运行"
	fi
}

restart() {
	stop
	start
}
status(){
        pid=$(getPid)
        if [ -n "$pid" ]; then
                echo "程序已经在运行: $pid"
                exit 1
        fi
}

help() {
echo "bash run.sh help"
cat << EOF
bash run.sh start

  start   启动服务
  stop    停止服务
  restart 重启服务
  status  查看pid 
EOF

}

main() {
	case $1 in
	"start")
		start
		;;
	"stop")
		stop
		;;
	"restart")
		restart
		;;
	"status")
		status
		;;
	*)
		help
                exit 1
	esac
}

main $1

```

## 安装NFS

略

## docker 镜像

### git

```
bitnami/git:2.37.1
```

### build

jdk + maven + node + nvm

```
ashrc
#!/bin/bash
# shellcheck source=/dev/null

# If not running interactively, don't do anything
#[[ $- != *i* ]] && return

# Load NVM
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Load compatibility NodeJS with alpine
export NVM_NODEJS_ORG_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release


```

Dockerfile

```
FROM alpine:3.15 as mvnCache

ADD jdk-8u271-linux-x64.tar /usr/local/
ADD apache-maven-3.5.4-bin.tar /usr/local/
ADD sgerrand.rsa.pub /tmp/
ADD glibc232.tar /tmp/
ADD ashrc /tmp/
COPY nvm /tmp/


FROM alpine:3.15

COPY --from=mvnCache /usr/local/jdk1.8.0_271 /usr/local/jdk1.8.0_271

COPY --from=mvnCache /usr/local/apache-maven-3.5.4 /usr/local/apache-maven-3.5.4
COPY --from=mvnCache /tmp/glibc232 /tmp/glibc232
COPY --from=mvnCache /tmp/sgerrand.rsa.pub /etc/apk/keys/
COPY --from=mvnCache /tmp/ashrc /root/.profile
COPY --from=mvnCache /tmp/nvm /usr/local/nvm

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \ 
  apk --no-cache add -U bash coreutils libstdc++ python2 make g++ tzdata ca-certificates && \
  apk --allow-untrusted --no-cache add /tmp/glibc232/glibc-* && \
  . "/usr/local/nvm/nvm.sh"  && \
  /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 && \
  ln -s /usr/local/nvm/versions/node /node && \
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
  rm -rf /tmp/* 

ENV ENV="/root/.profile"

ENV NVM_NODEJS_ORG_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/nodejs-release"
ENV LANG="zh_CN.UTF-8"
ENV JAVA_HOME="/usr/local/jdk1.8.0_271"
ENV CLASSPATH=".:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/jre/lib/rt.jar"
ENV MAVEN_HOME="/usr/local/apache-maven-3.5.4"
ENV MVND="/usr/local/mvnd-0.8.0-linux-amd64"
ENV PATH="$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin:/usr/glibc-compat/bin:${MAVEN_HOME}/bin:${MVND}/bin"

ENTRYPOINT ["/bin/sh","-l","-c"]
```

https://github.com/nodejs/docker-node/blob/main/Dockerfile-alpine.template


### ansible
