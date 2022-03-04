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

Ansible 开发分为两大模块，一是modules，二是plugins。

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


开发示例参考 
https://github.com/lework/Ansible-dev

https://ansible-tran.readthedocs.io/en/latest/docs/developing_plugins.html


## 开发环境
vscode + docker + ansible-module镜像

```
https://gitlab.com/techforce1/ansible-module.git
```

安装好vscode ,docker ，将git仓库拉取下来，使用vscode 打开仓库目录，会自动启动docker，生成开发环境


## 动手

开发一个minio 下载插件

### 思路

1、在ansible 服务端将文件现在到临时目录下保存
2、将临时目录中的文件发送的 客户端的临时目录
3、将客户端临时目录下的文件和客户端路径对比、替换 等操作


### minio
##### plugins

```
#!/usr/bin/python
# -*- coding: utf-8 -*-
from ansible.plugins.action import ActionBase
from ansible.errors import AnsibleError, AnsibleFileNotFound

from minio import Minio
from minio.error import S3Error

# from __future__ import (absolute_import, division, print_function)

__metaclass__ = type

import os
import shutil
import random
import string


class MinioUtils(object):
    def __init__(self, module) -> None:
        self.module = module
        self.name = module['name']
        self.state = module['state']
        self.endpoint = module['endpoint']
        self.access_key = module['access_key']
        self.secret_key = module['secret_key']
        self.bucket = module['bucket']
        self.src = module['src']
        self.dest = module['dest']
        self.filenameTmp = module['filenameTmp']

        self.minio_conf = {
            'endpoint': self.endpoint,
            'access_key': self.access_key,
            'secret_key': self.secret_key,
            'secure': False,
        }
        self.client = Minio(**self.minio_conf)

    def bucket_list_files(self):
        """
        列出存储桶中所有对象
        :param bucket_name: 桶名
        :param prefix: 前缀
        :return:
        """
        try:
            files_list = self.client.list_objects(
                bucket_name=self.bucket, prefix=self.src, recursive=True)
            lists = []
            for obj in files_list:
                lists.append(obj.object_name)
            return lists
        except S3Error as e:
            print("[error]:", e)

    def CreateTmp(self):
        isExists = os.path.exists(self.filenameTmp)
        # 判断结果
        if not isExists:
            # 如果不存在则创建目录
            # 创建目录操作函数
            os.makedirs(self.filenameTmp)
            return True
        else:
            # 如果目录存在则不创建，并提示目录已存在
            print(self.filenameTmp+' 目录已存在')
            return False

    def fget_minio(self):
        """
        下载保存文件保存本地
        :param bucket_name:
        :param file:
        :param file_path:
        :return:
        """
        try:
            self.CreateTmp()
            lists = self.bucket_list_files()
            for obj in lists:

                if not self.client.bucket_exists(self.bucket):
                    return 'Bucket does not exist'

                # if len(self.dest.split(".")) == 1:
                #     dest_name = "{}/{}".format(self.filenameTmp, obj.split("/")[-1])
                # else:
                #     dest_name = "{}".format(self.dest)

                dest_name = "{}/{}".format(self.filenameTmp,
                                           obj.split("/")[-1])
                data = self.client.fget_object(
                    self.bucket, obj, dest_name)
                result = {}
                result['size'] = data.size
                result['etag'] = data.etag
                result['content_type'] = data.content_type
                result['last_modified'] = data.last_modified
                result['metadata'] = data.metadata
                result['fullname'] = dest_name

            return result
        except S3Error as err:
            return err



class ActionModule(ActionBase):

    def run(self, tmp=None, task_vars=None):
        ''' handler for file transfer operations '''
        if task_vars is None:
            task_vars = dict()
        # 执行父类的run方法
        result = super(ActionModule, self).run(tmp, task_vars)

        if result.get('skipped'):
            return result

        # 获取参数
        module_args = self._task.args.copy()
        module_args['name'] = self._task.args.get(
            'name', None)
        module_args['state'] = self._task.args.get(
            'state', None)
        module_args['endpoint'] = self._task.args.get(
            'endpoint', None)
        module_args['access_key'] = self._task.args.get(
            'access_key', None)
        module_args['secret_key'] = self._task.args.get(
            'secret_key', None)
        module_args['bucket'] = self._task.args.get(
            'bucket', None)
        module_args['src'] = self._task.args.get(
            'src', None)
        module_args['dest'] = self._task.args.get(
            'dest', None)

        # 判定参数
        result['failed'] = True
        if module_args['src'] is None or module_args['dest'] is None:
            result['msg'] = "src and dest and accessToken  are required"

        else:
            del result['failed']

        if result.get('failed'):
            return result

        # 创建临时目录
        tmp = "/tmp"

        ran_str = ''.join(random.sample(
            string.ascii_letters + string.digits, 12))
        print(ran_str)

        # 临时 文件名称
        module_args['filenameTmp'] = "{}/{}".format(
            tmp, ran_str)

        # 获取minio 文件
        mu = MinioUtils(module_args)
        res = mu.fget_minio()
        # print("res: ", res)

        # 找到source的路径地址
        try:
            # source = self._find_needle('files', module_args['filenameTmp'])
            source = res['fullname']
            # print("source:", source)
        except AnsibleError as e:
            result['failed'] = True
            result['msg'] = to_text(e)
            return result

        # 获取本地文件，不存在抛出异常
        try:
            source_full = self._loader.get_real_file(source)
            source_rel = os.path.basename(source)
            print("source_full:", source_full)
            print("source_rel:", source_rel)
        except AnsibleFileNotFound as e:
            result['failed'] = True
            result['msg'] = "could not find src=%s, %s" % (source, e)
            self._remove_tmp_path(tmp)
            return result

        # 定义拷贝到远程的文件路径
        tmp_src = self._connection._shell.join_path(tmp, ran_str)
        print("tmp_src", tmp_src)

        # 判断文件保存的路径
        if len(module_args['dest'].split(".")) == 1:
            module_args['dest'] = "{}/{}".format(
                module_args['dest'], source_rel)

        # 远程文件
        remote_path = None
        remote_path = self._transfer_file(source_full, tmp_src)

        # 确保我们的文件具有执行权限
        if remote_path:
            self._fixup_perms2((tmp, remote_path))

        # 运行remote_copy 模块
        new_module_args = self._task.args.copy()
        new_module_args.update(
            dict(
                src=tmp_src,
                dest=module_args['dest'],
                original_basename=source_rel,
            )
        )

        module_return = self._execute_module(module_name='my_minio',
                                             module_args=new_module_args, task_vars=task_vars,
                                             tmp=tmp)

        # 判断运行结果
        if module_return.get('failed'):
            result.update(module_return)
            return result
        if module_return.get('changed'):
            changed = True

        if module_return:
            result.update(module_return)
        else:
            result.update(
                dict(dest=module_args['dest'], src=module_args['src'], changed=changed))

        # 清理临时文件
        self._remove_tmp_path(tmp_src)
        shutil.rmtree(tmp_src)

        # 返回结果
        return result

```

##### modules

```
#!/usr/bin/python
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import *

import os
import shutil


def main():

    # 定义modules需要的参数
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            state=dict(type='str', required=True),
            endpoint=dict(type='str', required=True),
            access_key=dict(type='str', required=True),
            secret_key=dict(type='str', required=True),
            bucket=dict(type='str', required=True),
            src=dict(type='str', required=True),
            dest=dict(type='str', required=True),
            original_basename=dict(required=False),
        ),
        supports_check_mode=True,
    )

    # 获取modules的参数
    original_basename = module.params.get('original_basename', None)
    src = module.params['src']
    dest = module.params['dest']
    b_src = to_bytes(src, errors='surrogate_or_strict')
    b_dest = to_bytes(dest, errors='surrogate_or_strict')

    # 判断参数是否合规
    if not os.path.exists(b_src):
        module.fail_json(msg="Source %s not found" % (src))
    if not os.access(b_src, os.R_OK):
        module.fail_json(msg="Source %s not readable" % (src))
    if os.path.isdir(b_src):
        module.fail_json(
            msg="Remote copy does not support recursive copy of directory: %s" % (src))

    # 获取文件的sha1
    checksum_src = module.sha1(src)
    checksum_dest = None

    changed = False

    # 确定dest文件路径
    if original_basename and dest.endswith(os.sep):
        dest = os.path.join(dest, original_basename)
        b_dest = to_bytes(dest, errors='surrogate_or_strict')

    # 判断目标文件是否存在
    if os.path.exists(b_dest):
        module.exit_json(msg="file already exists",
                         src=src, dest=dest, changed=False)
        if os.access(b_dest, os.R_OK):
            checksum_dest = module.sha1(dest)

    # 源文件与目标文件sha1值不一致时覆盖源文件
    if checksum_src != checksum_dest:
        if not module.check_mode:
            try:
                module.atomic_move(b_src, b_dest)
            except IOError:
                module.fail_json(msg="failed to copy: %s to %s" % (src, dest))
            changed = True

    else:
        changed = False

    # 返回值
    res_args = dict(
        dest=dest, src=src, checksum=checksum_src, changed=changed
    )

    module.exit_json(**res_args)


if __name__ == '__main__':
    main()

```



#### gitlab 文件下载

##### plugins
```
#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import (absolute_import, division, print_function)
import re
__metaclass__ = type

import json
import os
import stat
import tempfile
import gitlab

# from ansible.constants import mk_boolean as boolean
from ansible.errors import AnsibleError, AnsibleFileNotFound
from ansible.module_utils._text import to_bytes, to_native, to_text
from ansible.plugins.action import ActionBase
from ansible.utils.hashing import checksum


class GitlabUtils(object):
    def __init__(self, module) -> None:
        self.module = module
        self.name = module['name']
        self.url = module['url']
        self.accessToken = module['accessToken']
        self.src = module['src']
        self.dest = module['dest']
        self.projectID = module['projectID']
        self.branch = module['branch']
        self.filenameTmp = module['filenameTmp']

    # 登陆
    def login(self):
        gl = gitlab.Gitlab(self.url, self.accessToken)
        return gl

    # 获得项目：projectID的格式随意，反正我就写了个数字进去
    def getProject(self):
        gl = self.login()
        projects = gl.projects.get(self.projectID)
        return projects

    # 获得project下单个文件
    def getFile(self):
        projects = self.getProject()
        result = {}

        try:
            # 获得文件
            with open("{file}".format( file=self.filenameTmp), 'wb') as f:
                projects.files.raw(
                    file_path=self.src, ref=self.branch, streamed=True, action=f.write)

            result = {'changed': True, 'msg': "success"}

        except Exception as e:
            result = {'changed': False, 'msg': e}

        return result

class ActionModule(ActionBase):
    def run(self, tmp=None, task_vars=None):
        ''' handler for file transfer operations '''
        if task_vars is None:
            task_vars = dict()
        # 执行父类的run方法
        result = super(ActionModule, self).run(tmp, task_vars)

        if result.get('skipped'):
            return result

        # 获取参数
        module_args = self._task.args.copy()

        module_args['name'] = self._task.args.get(
            'name', None)
        module_args['url'] = self._task.args.get(
            'url', None)
        module_args['accessToken'] = self._task.args.get(
            'accessToken', None)
        module_args['src'] = self._task.args.get(
            'src', None)
        module_args['dest'] = self._task.args.get(
            'dest', None)
        module_args['projectID'] = self._task.args.get(
            'projectID', None)
        module_args['branch'] = self._task.args.get(
            'branch', None)

        # 判定参数
        result['failed'] = True
        if module_args['src'] is None or module_args['dest'] is None or module_args['url'] is None or module_args['accessToken'] is None or module_args['projectID'] is None:
            result['msg'] = "src and dest and url and accessToken and projectID are required"
        else:
            del result['failed']

        if module_args['branch'] is None:
            module_args['branch'] = 'master'

        if result.get('failed'):
            return result

        # 创建临时目录
        tmp = "/tmp"

        # 临时 文件名称
        module_args['filenameTmp'] = "{}/{}".format(tmp, module_args['src'].split("/")[-1])
        print("filenameTmp: ",module_args['filenameTmp'])

        # 获取gitlab 文件
        gl = GitlabUtils(module_args)
        res = gl.getFile()


        # 找到source的路径地址
        try:
            if ( res['changed'] ):
                print("true")
                source = self._find_needle('files', module_args['filenameTmp'])
            else:
                print("false",res['msg'])
                result['failed'] = True
                result['msg'] = str(res['msg'])
                return result
        except AnsibleError as e:
            result['failed'] = True
            result['msg'] = to_text(e)
            return result

        # 获取本地文件，不存在抛出异常
        try:
            source_full = self._loader.get_real_file(source)
            source_rel = os.path.basename(source)
        except AnsibleFileNotFound as e:
            result['failed'] = True
            result['msg'] = "could not find src=%s, %s" % (source, e)
            self._remove_tmp_path(tmp)
            return result

        # 定义拷贝到远程的文件路径
        tmp_src = self._connection._shell.join_path(tmp, 'source')

        # 判断文件保存的路径
        if len(module_args['dest'].split(".")) == 1 :
          module_args['dest'] = "{}/{}".format(module_args['dest'],source_rel)
          
        # 远程文件
        remote_path = None
        remote_path = self._transfer_file(source_full, tmp_src)

        # 确保我们的文件具有执行权限
        if remote_path:
            self._fixup_perms2((tmp, remote_path))

        # 运行remote_copy 模块
        new_module_args = self._task.args.copy()
        new_module_args.update(
            dict(
                src=tmp_src,
                dest=module_args['dest'],
                original_basename=source_rel,
            )
        )

        module_return = self._execute_module(module_name='my_gitlab',
                                             module_args=new_module_args, task_vars=task_vars,
                                             tmp=tmp)

        # 判断运行结果
        if module_return.get('failed'):
            result.update(module_return)
            return result
        if module_return.get('changed'):
            changed = True

        if module_return:
            result.update(module_return)
        else:
            result.update(
                dict(dest=module_args['dest'], src=module_args['src'], changed=changed))

        # 清理临时文件
        self._remove_tmp_path(tmp)

        # 返回结果
        return result

```

##### modules
```
#!/usr/bin/python
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import *

import os


def main():
    # 定义modules需要的参数
    module = AnsibleModule(
        argument_spec=dict(
            name=dict(type='str', required=True),
            url=dict(type='str', required=True),
            accessToken=dict(type='str', required=True),
            branch=dict(type='str', required=True),
            projectID=dict(type='str', required=True),
            src=dict(type='str', required=True),
            dest=dict(type='str', required=True),
            original_basename=dict(required=False),
        ),
        supports_check_mode=True,
    )

    # 获取modules的参数
    original_basename = module.params.get('original_basename', None)
    src = module.params['src']
    dest = module.params['dest']
    b_src = to_bytes(src, errors='surrogate_or_strict')
    b_dest = to_bytes(dest, errors='surrogate_or_strict')

    print("b_src --> ", b_src)
    # 判断参数是否合规
    if not os.path.exists(b_src):
        module.fail_json(msg="Source %s not found" % (src))
    if not os.access(b_src, os.R_OK):
        module.fail_json(msg="Source %s not readable" % (src))
    if os.path.isdir(b_src):
        module.fail_json(
            msg="Remote copy does not support recursive copy of directory: %s" % (src))

    # 获取文件的sha1
    checksum_src = module.sha1(src)
    checksum_dest = None

    changed = False

    # 确定dest文件路径
    if original_basename and dest.endswith(os.sep):
        dest = os.path.join(dest, original_basename)
        b_dest = to_bytes(dest, errors='surrogate_or_strict')

    # 判断目标文件是否存在
    if os.path.exists(b_dest):
        module.exit_json(msg="file already exists",
                         src=src, dest=dest, changed=False)
        if os.access(b_dest, os.R_OK):
            checksum_dest = module.sha1(dest)

    # 源文件与目标文件sha1值不一致时覆盖源文件
    if checksum_src != checksum_dest:
        if not module.check_mode:
            try:
                module.atomic_move(b_src, b_dest)
            except IOError:
                module.fail_json(msg="failed to copy: %s to %s" % (src, dest))
            changed = True

    else:
        changed = False

    # 返回值
    res_args = dict(
        dest=dest, src=src, checksum=checksum_src, changed=changed
    )

    module.exit_json(**res_args)

if __name__ == '__main__':
    main()


```