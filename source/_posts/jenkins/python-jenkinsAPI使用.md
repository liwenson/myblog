---
title: python-jenkins API 使用
date: 2021-10-29 15:14
categories:
- jenkins
tags:
- ci/cd
---
	
	
摘要: jenkins API使用
<!-- more -->


# Python Jenkins-Jenkins库初识
## 模块安装
```
pip install pbr
pip install python-jenkins
```

## 模块使用方法

### 初始化Jenkins连接
```
jk = jenkins.Jenkins(url='Jenkins地址', username='用户名', password='授权令牌')
```

### Job基本操作
#### Job创建


创建有2种方式，可以创建一个新的，也可以基于已有的Job模板创建
我这里使用Job模板创建
```
xml = jk.get_job_config('模板job名称')    # 获取模板配置文件
jk.create_job(name='新的job名称', config_xml=xml)
```

#### 构建Job
构建有2种方式：
普通构建
```
jk.build_job(name='构建的job名称')
```

参数化构建
```
jk.build_job(name='构建的job名称', parameters='构建的参数，字典类型')  //param_dict={"param1"："value1"， "param2"："value2"}
```

#### 停止一个正在运行的Job
```
jk.stop_build('job名称', '构建编号ID')
```

#### 激活Job状态为可以构建
```
jk.enable_job('job名称')
```

#### 变更Job状态为不可以构建
```
jk.disable_job('job名称')
```

#### 删除Job
```
jk.delete_job('job名称')
```


### 获取Job信息
#### 获取Job的初始配置参数
就是Job的Build with Parameters内容

```
result = []
for each in jk.get_job_info('job名称')['property']:
    if 'ParametersDefinitionProperty' in each['_class']:
        data = each['parameterDefinitions']
        for params in data:
            temp_dict = dict()
            temp_dict['name'] = params['defaultParameterValue']['name']
            temp_dict['value'] = params['defaultParameterValue']['value']
            temp_dict['description'] = params['description']
            result.append(temp_dict)
print(result)
```

#### 获取Job任务状态
获取流程：先获取到构建编号，再通过构建编号获取任务状态

这里我们一般是获取最后一次构建的任务状态，所以要先获取到最后一次构建的编号：

```
last_build_number = jk.get_job_info('job名称')['lastBuild']['number']
```

通过构建编号获取任务状态:
```
status = jk.get_build_info('job名称', last_build_number)['result']
print(status)   # 状态有4种：SUCCESS|FAILURE|ABORTED|pending
```


#### 获取Job控制台日志
通过构建编号获取控制台日志：

```
result = jk.get_build_console_output(name='job名称', number=last_build_number)
print(result)
```

#### 获取Job测试报告
通过构建编号获取测试报告：
```
result = jk.get_build_test_report(name='job名称', number=last_build_number)
print(result)
```



## 示例

[官方示例git地址]( https //github.com/pycontribs/jenkinsapi/tree/master/examples )

```
#导入jenkins库
import jenkins

#定义远程的jenkins master server 的url,以及port
jenkins_server_url = 'http://127.0.0.1:8080/jenkins'

#定义用户的Userid 和 api token
user_id = 'admin'
api_token = '11a7a8151dbde5173fa19b346ad46b5efe'

#实例化jenkins对象，连接远程的jenkins master server
server = jenkins.Jenkins(jenkins_server_url,username=user_id,password=api_token)

#打印一下server查是否连接成功
# print(server) #返回一个jenkins对象<jenkins.Jenkins object at 0x10807d190>

# 构建job名为testJob的job（不带构建参数）
# server.build_job('testJob')

#构建job名为job_name的job（不带构建参数）
server.build_job(job_name)
#String参数化构建job名为job_name的job, 参数param_dict为字典形式，如：param_dict= {"param1"：“value1”， “param2”：“value2”} 
server.build_job('testJob',param_dict= {"param1"："value1"， "param2"："value2"} )

#查看某个job的构建信息
job_info = server.get_job_info('testJob')
# print(job_info)


#获取job名为testJob的job的最后次构建号
lastbuildNumber = server.get_job_info('testJob')['lastBuild']['number']

#获取job名为testJob的job的最后1次构建的执行结果状态
result = server.get_build_info('testJob',lastbuildNumber)['result']

#判断testJob是否还在构建中
status = server.get_build_info('testJob',lastbuildNumber)['building']
print(status)

```


### python调用Job执行

```
from threading import Event, Thread
import jenkins
import threading
import logging
import datetime

FORMAT = '%(asctime)s %(threadName)s %(thread)s %(message)s'
logging.basicConfig(format=FORMAT, level=logging.INFO)

# server = jenkins.Jenkins('http://jenkins.pingcode.live', username='daizhe', password='EgKXD1LY01mxhufr')
server = jenkins.Jenkins('http://localhost:8080/', username='root', password='12345678')
all_jobs = server.get_all_jobs()
# print(all_jobs)

# 事件驱动器
event = Event()   # False

def jobstart(e, name):
    worker_jobs = []
    for item in all_jobs:
        # Job名称
        names = item['name']
        # Job链接
        urls = item['url']
        # Job状态颜色
        colors = item['color']
        # print(item['name'], item['url'], item['color'])
        if names == name:
            logging.info("{}. 开始部署!!!!")
            server.build_job(name)
            lastbuildNumber = server.get_job_info(name)['lastBuild']['number']
            worker_jobs.append(lastbuildNumber)
        e.set()             # True

def jobwatch(e, name):
        e.wait()
        try:
            # 获取job名为testJob的job的最后次构建号
            lastbuildNumber = int(server.get_job_info(name)['lastBuild']['number']) + 1
            logging.info("Job Number : {}".format(lastbuildNumber))

            # 获取job名为testJob的job的最后1次构建的执行结果状态
            # print(server.get_build_console_output(name, number=lastbuildNumber))

            # 判断Job是否还在构建中
            status = server.get_build_info(name, lastbuildNumber)['building']  # bool
            print(status, '`````````')

            while True:
                if status:
                    logging.info("{}. 已经部署完毕!!!".format(name))
                else:
                    logging.info("{}. 正在部署中!!!".format(name))
                    # while True:
                    #     if
                    break
        except Exception as e:
            print(e)
        finally:
            pass

if __name__ == "__main__":
    job_name = "itsm_pipeline_test_job"
    th1 = threading.Thread(target=jobstart, name='jobstart', args=(event, job_name))
    th2 = threading.Thread(target=jobwatch, name='jobwatch', args=(event, job_name))
    th1.start()
    th2.start()



# print("所有的Job信息打印")
# for jb in all_jobs:
#     names = jb['name']
#     print(names, sep='')



# Job_name = input("输入Job名称 >>>")



# 参数
# param_dict = {"RUN_EVN" : "RUN_EVN",
#               "TAG_NAME" : "TAG_NAME",
#               }



        # console = server.get_build_console_output(names)
        # print(console)

    # 问题 ：
        # 如何检索出视图，然后再遍历视图中的job

    # build_info = server.get_job_info(item['name'])
    # print(build_info)

```

### python-Jenkins批量创建及修改jobs操作

使用 jobsName.ini 文件保存要创建job的名字

jobs1
jobs2
jobs3

使用Jenkins创建job时自动生成的config.xml文件为模板进行批量创建jobs或修改jobs，一般生成的job会在你安装的Jenkins目录下找到

```
import jenkins

jobsOperation = input("请选择是新建jobs还是修改jobs：\na.创建jobs \nb.修改jobs \n")

# 连接远程Jenkins
server=jenkins.Jenkins("http://127.0.0.1:8080/", username="admin", password="admin")
# 读取及修改的配置模板
pathConfigxml = open("config.xml",encoding='utf-8').read()

# 读取要创建的jobs名称
def readJobsName():
  jobnames = open('jobsName.ini',encoding="utf-8")
  return jobnames
  pass

# 读取要修改配置的jobs名称
def readChangeJobsName():
  changeJobsName = open('changeJobsName.ini', encoding='utf-8')
  return changeJobsName
  pass

# 创建新的jobs
def createNewJobs():
  jobsname = readJobsName()
  for jobName in jobsname:
    server.create_job(jobName.replace("\n",""),pathConfigxml)

  pass

# 批量修改已有的jobs
def changeJobs():
  changeJobsName = readChangeJobsName()
  for changeJobName in changeJobsName:
    server.reconfig_job(changeJobName.replace("\n",""), pathConfigxml)
  pass

if "a"==jobsOperation:
  createNewJobs()
elif "b"==jobsOperation:
  changeJobs()
else:print("未选择操作，退出任务！")
```


### 禁用jenkins中某一个job任务
```
import requests

#python写一个功能:禁用jenkins某一个任务(job)
print(requests.get('http://localhost:8080/jenkins/job/Test_version/').text)
url = 'http://localhost:8080/jenkins/job/Test_version/disable'
re = requests.post(url, data={}, auth=('wyq', 'wyq'))
print(re.status_code)
print(re.headers)
print(re.reason)
```

### Python-jenkins方法封装
jenkinsInit.py
```
# -*- coding:utf8 -*-
from configparser import ConfigParser

import os
import sys
import jenkins
import getopt


class ReadConfigFile(object):
    def read_config(self):
        conn = ConfigParser()
        file_path = os.path.join(os.path.abspath('.'),'config.ini')
        if not os.path.exists(file_path):
            raise FileNotFoundError("文件不存在")
        conn.read(file_path)
        return conn


class JenkinsImpl(object):
    def __init__(self,conf,file):
        self.rs=conf.read_config()
        self.server=jenkins.Jenkins(self.rs.get("system","Jenkins_URL"), username=self.rs.get("system","Jenkins_USER"), password=self.rs.get("system","Jenkins_Token"))
        # 读取及修改的配置模板
        self.config_xml = open(file,encoding='utf-8').read()

    def CreateJob(self,ProjectName):
      """
      创建项目
      """
      if self.server.job_exists(ProjectName) != True :
          print("项目不存在开始新建项目")
          self.server.create_job(ProjectName,self.config_xml)
      else:
          print("项目已存在!")

    def DeleteJob(self,ProjectName):
      """
      删除项目
      """
      if self.server.job_exists(ProjectName) == True :
        print("项目已存在!")
        self.server.delete_job(ProjectName)
      else:
        print("项目不存在")


    def CopyJob(self,ProjectName,NewProjectName):
      """
      复制项目
      """
      if self.server.job_exists(ProjectName) == True :
        print("项目已存在!")
        self.server.copy_job(ProjectName,NewProjectName)
      else:
        print("项目不存在")


    def EnableJob(self):
      """
      启用被禁止的项目
      """
      if self.server.job_exists(ProjectName) == True :
        print("项目已存在!")
        self.server.enable_job(ProjectName)
      else:
        print("项目不存在")

    def DisableJob(self,ProjectName):
      """
      禁用项目
      """
      if self.server.job_exists(ProjectName) == True :
        print("项目已存在!")
        self.server.disable_job(ProjectName)
      else:
        print("项目不存在")

    def RenameJob(self,ProjectName,NewProjectName):
      """
      重命名Job
      """
      if self.server.job_exists(ProjectName) == True :
        print("项目已存在!")
        self.server.rename_job(ProjectName,NewProjectName)
      else:
        print("项目不存在")

    def GetJobs(self,ProjectName):
      '''
      获取所有的Job
      '''
      print(self.server.get_jobs())


if __name__ == '__main__':
  # ji.CreateJob(ProjectName)
  try:
    opts,args = getopt.getopt(sys.argv[1:],'-m:-n:-f:-h-v',['name=','method=','file=','help','version'])
    for opt_name,opt_value in opts:
      if opt_name in ('-h','--help'):
        print("[*] Help info")
        print("""
        -h  --help     帮助
        -m  --method   方法
                -m CreateJob -n abc
                -m DeleteJob -n abc
        -n   --name   job名称        
        """)
        sys.exit()
      if opt_name in ('-v','--version'):
        print("[*] Version is 0.01 ")
        sys.exit()
      if opt_name in ('-n','--name'):
        ProjectName = opt_value
      if opt_name in ('-m','--method'):
        Method = opt_value
      if opt_name in ('-f','--file'):
        filename = opt_value
  except getopt.GetoptError as e:
    print ('Got a eror and exit, error is %s' % str(e))

  rc = ReadConfigFile()
  ji=JenkinsImpl(rc,filename)

  if ( Method == 'CreateJob' ):
    if ProjectName is not None:
      ji.CreateJob(ProjectName)
    else:
      print("ProjectName is null")
  elif ( Method == 'DeleteJob' ):
    if ProjectName is not None:
      ji.DeleteJob(ProjectName)
    else:
      print("ProjectName is null")
  elif ( Method == 'CopyJob' ):
    if ProjectName is not None and NewProjectName is not None:
      ji.CopyJob(ProjectName,NewProjectName)
  elif ( Method == 'EnableJob' ):
    if ProjectName is not None:
      ji.EnableJob(ProjectName)
    else:
      print("ProjectName is null")
  else:
    print ('No Method...')

```

config.ini
```
[system]
Jenkins_URL = "http://10.200.75.213:8081/"
Jenkins_USER = "admin"
Jenkins_Token = "11eadee7c929b7e37f3a7768f986788655"
```


使用
```
python jenkinsInit.py -n test001 -m CreateJob -f /tmp/config.xml
```


## jenkins 配置文件模板制作
编写好 pipelinefile 文件
使用 pipelinefile文件创建一个标准 pipeline 项目
下载 该项目的配置文件
```
curl -X GET http://10.200.75.213:8081/job/test999/config.xml -u admin:11eadee7c929b7e37f3a7768f986788655 -o mylocalconfig.xml
```

通过修改这个配置，做成模板文件
