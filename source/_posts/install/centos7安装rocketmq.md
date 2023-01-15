---
title: centos7安装RocketMQ
date: 2021-07-29 16:00
categories:
- centos7
tags:
- rocketmq
---


## systemctl 管理

### nameserver

/usr/lib/systemd/system/rocketmq-name.service

```bash
[Unit]
Description=rmq
After=network.target

[Service]

#这里Type一定要写simple
Type=simple  

#ExecStart和ExecStop分别在systemctl start和systemctl stop时候调动
ExecStart=/opt/rocketmq-4.6.1-ztocwst/bin/mqnamesrv -c /usr/local/rocketmq/bin/namesrv.properties
ExecStop=/usr/local/rocketmq/bin/mqshutdown namesrv

[Install]
WantedBy=multi-user.target
```

```
cat > /usr/lib/systemd/system/rmq-namesrv.service  << EOF
[Unit]
Description=rocketmq-nameserver
After=network.target

[Service]
#User=rockmq
Type=simple
WorkingDirectory=/opt/rocketmq-4.6.1-ztocwst
ExecStart=/opt/rocketmq-4.6.1-ztocwst/bin/mqnamesrv
ExecReload=/bin/kill -s HUP \$MAINPID
#ExecStop=/bin/kill -s QUIT \$MAINPID
ExecStop=/opt/rocketmq-4.6.1-ztocwst/bin/mqshutdown namesrv
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF



cat > /usr/lib/systemd/system/rmq-broker-n0.service  << EOF
[Unit]
Description=rocketmq-broker
After=network.target

[Service]
#User=rockmq
Type=simple
WorkingDirectory=/opt/rocketmq-4.6.1-ztocwst
ExecStart=/opt/rocketmq-4.6.1-ztocwst/bin/mqbroker -c /opt/rocketmq-4.6.1-ztocwst/conf/dledger/n0-broker-n0.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF



cat > /usr/lib/systemd/system/rmq-broker-n1.service  << EOF
[Unit]
Description=rocketmq-broker
After=network.target

[Service]
#User=rockmq
Type=simple
WorkingDirectory=/opt/rocketmq-4.6.1-ztocwst
ExecStart=/opt/rocketmq-4.6.1-ztocwst/bin/mqbroker -c /opt/rocketmq-4.6.1-ztocwst/conf/dledger/n1-broker-n0.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

```bash
systemctl daemon-reload
systemctl start rmq-namesrv.service && systemctl enable rmq_namesrv.service

systemctl start rmq-broker-n0.service && systemctl enable rmq_broker.service

systemctl start rmq-broker-n1.service && systemctl enable rmq_broker.service

systemctl status rmq-broker-n0 rmq-broker-n1 rmq_namesrv
```
