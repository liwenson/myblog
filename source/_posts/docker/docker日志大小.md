---
title: docker限制日志大小
date: 2021-06-28 16:01
categories:
- docker
tags:
- docker
- log
---
	
	
摘要: docker限制日志大小
<!-- more -->


## 限制Docker日志大小
如果Docker日志不限制大小，直接导致磁盘空间被用完，影响服务的可用性。

修改docker配置文件，`vim /etc/docker/daemon.json`

```
{
  "log-driver":"json-file",
  "log-opts": {"max-size":"500m", "max-file":"3"}
}
```

>max-size=500m，意味着一个容器日志大小上限是500M <br>
max-file=3，意味着一个容器有三个日志，分别是id+.json、id+1.json、id+2.json。

然后重启docker的守护线程
```
systemctl daemon-reload
systemctl restart docker
```

## docker-compose 限制日志大小

```
docker-compose.yml中也可以限制 

nginx:
  image: nginx:1.12.1
  restart: always
  logging:
    driver: "json-file"
    options:
      max-size: "5g"
```

## docker run 限制日志大小
```
docker run -d --log-opt max-size=1g nginx
```



/etc/sysconfig/docker
```
# Modify these options if you want to change the way the docker daemon runs
OPTIONS='--selinux-enabled --log-driver=journald --signature-verification=false'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi


# Modify these options if you want to change the way the docker daemon runs
OPTIONS='--selinux-enabled  --signature-verification=false'
if [ -z "${DOCKER_CERT_PATH}" ]; then
    DOCKER_CERT_PATH=/etc/docker
fi

```
