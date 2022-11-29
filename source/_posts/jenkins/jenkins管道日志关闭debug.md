!---
title: jenkins输出屏蔽日志
date: 2022-09-16 09:49
categories:
- jenkins
tags:
- pipeline
---
  
  
摘要: 关闭jenkins pipeline中sh命令的debug模式
<!-- more -->

将脚本模式从调试（set -x）更改为命令记录（set -v）。在脚本敏感部分的结尾，将 Shell 重置为调试模式

```bash
    sh """
       # change script mode from debugging to command logging
       set +x -v

       # capture data from secret in shell variable
       MY_SECRET=\$(kubectl get secret my-secret --no-headers -o 'custom-column=:.data.my-secret-data')

       # replace template placeholder inline
       sed s/%TEMPLATE_PARAM%/${MY_SECRET_DATA}/ my-template-file.json
       
       # do something with modified template-file.json...

       # reset the shell to debugging mode
       set -x +v
    """

```
