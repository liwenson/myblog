---
title: ssh 免密登陆脚本
date: 2021-08-19 10:25
categories:
- linux
tags:
- ssh
---


摘要: ssh免密登陆
<!-- more -->

sssh.sh

```
#!/bin/bash

cat hosts.txt | while read var_host; do
var_host_name=`echo "${var_host}" | awk '{print $1}'` && echo "${var_host_name}"
#var_host_password=`echo "${var_host}" | awk '{print $2}'` && echo "${var_host_password}"
# 定义密码
var_host_password=vUIMrQPJ7xeJZf8I
/usr/bin/expect <<END
spawn ssh-copy-id ${var_host_name}
expect {
"*(yes/no)?" {send "yes\r";exp_continue}
"*password:" {send "${var_host_password}\r";exp_continue}
expect eof
}
END
ssh ${var_host_name} <<END
sed -r -i -e '/^[ \t]*#[ \t]* ForwardAgent /c ForwardAgent yes' /etc/ssh/ssh_config
service sshd reload
END
done
```

host.txt 
```
root@39.108.253.201
```
