---
title: Playbook支持任务结果回显
date: 2020-10-09 11:13
categories:
- ansible
tags:
- ansible
---
  
  
摘要: Playbook支持任务结果回显，不只是执行是否成功
<!-- more -->

### 配置文件
ansible.cfg 配置文件（变更callback路径位置）
```
[defaults]
callback_plugins=/etc/ansible/callback_plugins
# change the default callback
#stdout_callback = result_echo
# enable additional callbacks
callback_whitelist = result_echo
bin_ansible_callbacks = Ture

```

### 编写回显callback脚本
```
mkdir /etc/ansible/callback_plugins

cd /etc/ansible/callback_plugins
vim result_echo.py
```
```
#!/usr/bin/env python
# -*- coding=utf-8 -*-
######################
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.plugins.callback.default import CallbackModule as CallbackModule_default

class CallbackModule(CallbackModule_default):

    '''
    Execution result echo
    '''

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    #CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'result_echo'

    def __init__(self):
        super(CallbackModule, self).__init__()
        self.lock_results = None

    def on_any(self, *args, **kwargs):
        pass
    def runner_on_failed(self, host, res, ignore_errors=False):
        pass
    def runner_on_ok(self, host, res):
        #pass
        print(res)
    def runner_on_skipped(self, host, item=None):
        pass
    def runner_on_unreachable(self, host, res):
        #pass
        print(res)
    def runner_on_no_hosts(self):
        pass
    def runner_on_async_poll(self, host, res, jid, clock):
        pass
    def runner_on_async_ok(self, host, res, jid):
        pass
    def runner_on_async_failed(self, host, res, jid):
        pass
    def playbook_on_start(self):
        pass
    def playbook_on_notify(self, host, handler):
        pass
    def playbook_on_no_hosts_matched(self):
        pass
    def playbook_on_no_hosts_remaining(self):
        pass
    def playbook_on_task_start(self, name, is_conditional):
        pass
    def playbook_on_vars_prompt(self, varname, private=True, prompt=None, encrypt=None, confirm=False, salt_size=None, salt=None, default=None):
        pass
    def playbook_on_setup(self):
        pass
    def playbook_on_import_for_host(self, host, imported_file):
        pass
    def playbook_on_not_import_for_host(self, host, missing_file):
        pass
    def playbook_on_play_start(self, name):
        pass
    def playbook_on_stats(self, stats):
        pass
    def on_file_diff(self, host, diff):
        pass
    def v2_on_any(self, *args, **kwargs):
        pass
    def v2_runner_on_failed(self, result, ignore_errors=False):
        #pass
        #print (result.__dict__.items())
        #if "stderr_lines" in result._result.keys():
        #    print( result._result['stderr_lines'])
        #if 'state' in result._result.keys():
        #    print( result._result['state'])
        #if 'invocation' in result._result.keys():
        #    print( result._result['invocation'])
    def v2_runner_on_ok(self, result):
        if "stdout" in result._result.keys():
            print( result._result['stdout'])
        if 'state' in result._result.keys():
            print( result._result['state'])
        if 'invocation' in result._result.keys():
            print( result._result['invocation'])
        #pass
    def v2_runner_on_skipped(self, result):
        pass
    def v2_runner_on_unreachable(self, result):
        pass
    def v2_runner_on_no_hosts(self, task):
        pass
    def v2_runner_on_async_poll(self, result):
        pass
    def v2_runner_on_async_ok(self, result):
        pass
    def v2_runner_on_async_failed(self, result):
        pass
    def v2_runner_on_file_diff(self, result, diff):
        pass
    def v2_playbook_on_start(self, playbook):
        pass
    def v2_playbook_on_notify(self, result, handler):
        pass
    def v2_playbook_on_no_hosts_matched(self):
        pass
    def v2_playbook_on_no_hosts_remaining(self):
        pass
    def v2_playbook_on_task_start(self, task, is_conditional):
        pass
    def v2_playbook_on_cleanup_task_start(self, task):
        pass
    def v2_playbook_on_handler_task_start(self, task):
        pass
    def v2_playbook_on_vars_prompt(self, varname, private=True, prompt=None, encrypt=None, confirm=False, salt_size=None, salt=None, default=None):
        pass
    def v2_playbook_on_setup(self):
        pass
    def v2_playbook_on_import_for_host(self, result, imported_file):
        pass
    def v2_playbook_on_not_import_for_host(self, result, missing_file):
        pass
    def v2_playbook_on_play_start(self, play):
        pass
    def v2_playbook_on_stats(self, stats):
        pass
    def v2_on_file_diff(self, result):
        pass
    def v2_playbook_on_include(self, included_file):
        pass
    def v2_runner_item_on_ok(self, result):
        pass
    def v2_runner_item_on_failed(self, result):
        pass
    def v2_runner_item_on_skipped(self, result):
        pass
    def v2_runner_retry(self, result):
        pass
```

### 方法的result值
print(result._task) 输出任务名
print(result._check_key)
print(result._host) 输出主机名
print(result._result) 输出任务执行的结果
print(result.is_changed)
print(result.is_failed)


### 定义callback说明信息
CALLBACK_VERSION = 2.0 插件版本
CALLBACK_TYPE = 'aggregate' 插件类型，如果是'stdout'时，只会加载一个这样的回调插件
CALLBACK_NAME = 'timer' 插件名称，需与文件名称一致。
CALLBACK_NEEDS_WHITELIST = True 插件是否需要在配置文件配置whitelist。为true是，ansible检查ansible.cfg文件中的callback_whitelist是否有插件名称，有则执行，无则跳过。
