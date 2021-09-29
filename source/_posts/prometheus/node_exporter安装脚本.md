---
title:  node_exporter 安装脚本
date: 2020-09-21 18:47
categories:
- prometheus
tags:
- prome
- node_exporter
---
  
  
摘要: 安装node_exporter脚本， 用于监控数据采集
<!-- more -->

```bash
#!/bin/bash
#
#   rhel7.4 安装node_exporter 用于监控数据采集
#   Usage:
#         sh addNode.sh
#Logs: /var/log/messages
#History:  2019/8/2 v3
#Create_Time: 2019-08-02
# USE: small_wei
#
#
#WEB_PATH='http://12.0.94.46:8086'       #这里是我测试环境下的文件下载链接路径
# https://github.com/prometheus/node_exporter   官方下载地址
WEB_PATH='https://package-dev-qafc.aaa.com/res/node_exporter'
Install_PATH=/opt/node_exporter
Server_file=/usr/lib/systemd/system
prot=6301
RED_COLOR='\E[1;31m'  #红
GREEN_COLOR='\E[1;32m' #绿
RES='\E[0m'
node_user=prometheus
node_group=prometheus
Time_date=$(date +"%Y%m%d%H%M%S")
if [ ! $(id -u) == 0 ];then
    echo -e "${GREEN_COLOR}Please run with the root user!${RES}"
    exit 22
fi
#防止重复执行
if [ $(ps -ef | grep $0 |grep -v grep | wc -l) -gt 2 ];then    #理论值为 1,但这里是 2 
        echo -e "${RED_COLOR} $0  The script is executing, do not repeat!, Run id is $$${RES}"
        exit 22
fi
#create group if not exists
egrep "^${node_group}" /etc/group 2>/dev/null
if [ $? -ne 0 ];then
    groupadd ${node_group}
    echo -e "${node_group} group Creating a successful"
fi
#create user if not exists
egrep "^${node_user}" /etc/passwd 2>/dev/null
if [ $? -ne 0 ];then
    useradd -g ${node_group} ${node_user}
    echo -e "${node_user} user Creating a successful"
fi
port=`netstat -tunlp|grep ${prot}`
if test -z "${port}"
then
    [[ ! -d ${Install_PATH} ]] && mkdir -p ${Install_PATH} || echo "存在"
    chown -R ${node_user}:${node_user} ${Install_PATH}
    cd ${Install_PATH}
    curl -u ztycroot:dwI6TNCe -O $WEB_PATH
    chmod +x  ${Install_PATH}/node_exporter
    if [[ $? == 0 ]];then
        echo -e "${GREEN_COLOR}Environment readiness complete${RES}"
    fi
#-----------------
    if [  -f "${Server_file}/node_exporter.service" ];then
	    [[ ! -d /opt/back/ ]] && mkdir -p /opt/back/ || echo "已存在"
        cp -f ${Server_file}/node_exporter.service /opt/back/node_exporter.service.bak${Time_date}
    fi
    if [ $? == 0 ];then
        echo -e "${GREEN_COLOR}node_exporter.service.bak${Time_date}  File The backup successful${RES}"
    else
        echo -e "${RED_COLOR}node_exporter.service.bak${Time_date} File backup failed${RES}"
        exit 22
    fi
cat >${Server_file}/node_exporter.service <<-EOF
[Unit]
Description=Prometheus node exporter
Documentation=https://prometheus.io/
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target
[Service]
User=${node_user}
Group=${node_group}
Type=simple
#ExecStart=${Install_PATH}/node_exporter --web.listen-address=:9100 --log.level=error
#ExecStart=${Install_PATH}/node_exporter --web.listen-address=:${prot} --log.level=error

ExecStart=${Install_PATH}/node_exporter --web.listen-address=:${prot} --log.level=error \\
          --no-collector.softnet \\
          --no-collector.nfs \\
          --no-collector.hwmon \\
          --no-collector.mdadm

ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=20s
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl restart node_exporter
    if [ $? == 0 ];then
        echo -e  "${GREEN_COLOR}node_exporte  Server start success!${RES}"
    else
        echo -e  "${RED_COLOR}node_exporte  Server start ERROR!${RES}"
        exit 22
    fi
#------------------
else
    echo -e "${GREEN_COLOR}port:${prot} is busy,failed${RES}"
fi
systemctl enable node_exporter
systemctl status node_exporter
#验证
code=`curl -I -m 3 -o /dev/null -s -w %{http_code}  127.0.0.1:${prot}`
if [ ${code} == 200 ];then
    echo -e  "${GREEN_COLOR}register node in consul success${RES}"
else
    echo -e "${RED_COLOR}Registration failed or registered, please check! ${RES}"
    exit 22
fi
```

