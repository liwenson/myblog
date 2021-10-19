---
title: gitlab+droneci
date: 2021-10-14 14:41
categories:
- k8s
tags:
- droneci
---
	
	
摘要: desc
<!-- more -->

## 前言
公司之前一直在使用 Jenkins 作为 CI/CD 工具， Jenkins 非常强大，它完成了几乎所有 CI/CD 的工作，并且应用于整个团队有好长一段时间了。但是随着公司推荐数字化、智慧化，以及服务容器化的推进， Jenkins 的一些弊端也凸显了出来：

- 重量级： Jenkins 功能十分齐全，几乎可以做所有的事情。但是这也是他的一个弊端，过于重量级，有时候往往一个小的修改需要改动许多地方，升级\下载插件后需要进行重启等。
- 升级不易： 在一些安全 Jenkins 相关的安全漏洞被公开后，我们会对 Jenkins 进行升级，但这也不是一件容易的事。之前就出现过升级\重启后，所有 job 丢失，虽然我们所有项目配置都是以 Jenkinsfile 的形式统一存储，但是每个 job 都需要重新重新创建，包括每个 job 的权限....._(´ཀ`」 ∠)_
- 权限控制复杂： 这其实也是 Jenkins 的一大优势，可以精确控制每个用户的权限，但是需要花费更多时间去配置，时间长了也会出现权限混乱的问题。
- UI 界面： 这个其实是吐槽最多的部分，虽然有诸如：Blue Ocean 这样的插件来展示 pipeline ，但是还是没有从根本改变它简陋的 UI 界面。

<hr>

**那么为什么选择使用 Drone 呢？**

其实在 GitHub 上提交 PR 后，大部分开源项目都会使用 travis-ci 对提交的代码进行 CI 及检查，而如果是 Kubernetes 相关的项目，则会使用 prow 进行 CI。但是 travis-ci 只能用于 GitHub ，在寻找类似项目的时候， Drone 进入了我的视野。

大道至简。和 Jenkins 相比， Drone 就轻量的多了，从应用本身的安装部署到流水线的构建都简洁的多。由于是和源码管理系统相集成，所以 Drone 天生就省去了各种账户\权限的配置，直接与 gitlab 、 github 、 Bitbucket 这样的源码管理系统操作源代码的权限一致。

## 搭建 Drone (Docker)

[官方文档](https://docs.drone.io/server/overview/)
官方推荐使用 docker 的方式运行 Drone


### 准备gitlab
打开 settings----> application

在Redirect URI写入 Drone web 登陆地址: (login必须写的如果不写必然出问题)

http://10.200.75.213:80/login

然后记录 Application ID 和 Secret


<table>
    <tr>        
				<td colspan="2">Application: drone</td>
   </tr>
    <tr>  
        <td >Application ID</td>
				<td >492d4ca593a450d8216ed124a8e94b5dffb4f95845c7ca163455da74519f51cf</td>  
    </tr>
    <tr>
        <td >Secret</td>
				<td >29161ed6b2a420325c0477856372bf2313470d3dea8d5ed24e7401822aa6c71f</td>  
    </tr>
    <tr>
        <td >Callback URL</td>
				<td >http://10.200.75.213:80/login</td>  
    </tr>		
</table>



### 准备droneci server 的docker
- 下载镜像
```
docker pull drone/drone:2
```

- 准备通信的 DRONE_RPC_SECRET
```
openssl rand -hex 16
```

### Drone 服务器是使用环境变量配置

|-|-|
|---|---|
| DRONE_GITLAB_CLIENT_ID | 必需的字符串值提供您的 GitLab oauth 客户端 ID |
| DRONE_GITLAB_CLIENT_SECRET | 必需的字符串值提供您的 GitLab oauth 客户端密钥 |
| DRONE_GITLAB_SERVER |     选项字符串值提供您的 GitLab 服务器 URL。 <br/>默认值是 gitlab.com 服务器地址在 https://gitlab.com |
| DRONE_GIT_ALWAYS_AUTH | 可选的布尔值将 Drone 配置为在克隆公共存储库时进行身份验证。 这应该只在使用自托管 GitLab 和私有模式启用时启用。 |
| DRONE_RPC_SECRET |  必需的字符串值提供在上一步中生成的共享密钥。 这用于验证服务器和运行程序之间的 rpc 连接。 服务器和运行器必须提供相同的秘密值 |
| DRONE_SERVER_HOST |  必需的字符串值提供您的外部主机名或 IP 地址。 如果使用 IP 地址，您可以包含端口。 例如， drone.domain.com |
| DRONE_SERVER_PROTO | 必需的字符串值提供您的外部协议方案。 此值应设置为 http或者 https. 如果您配置 ssl 或 acme，则此字段默认为 https。 |


[更多配置参数](https://docs.drone.io/server/reference/)


### 启动 Drone-Server
- 例子
```
docker run \
  --volume=/var/lib/drone:/data \
  --env=DRONE_GITLAB_SERVER=http://git.ztoyc.zt \
  --env=DRONE_GITLAB_CLIENT_ID={{DRONE_GITLAB_CLIENT_ID}} \
  --env=DRONE_GITLAB_CLIENT_SECRET={{DRONE_GITLAB_CLIENT_SECRET}} \
  --env=DRONE_RPC_SECRET={{DRONE_RPC_SECRET}} \
  --env=DRONE_SERVER_HOST={{DRONE_SERVER_HOST}} \
  --env=DRONE_SERVER_PROTO={{DRONE_SERVER_PROTO}} \
  --publish=80:80 \
  --publish=443:443 \
  --restart=always \
  --detach=true \
  --name=drone \
  drone/drone:2
```

- 实例
```
docker run \
  --volume=/var/lib/drone:/data \
  --env=DRONE_GITLAB_SERVER=http://git.ztoyc.com \
  --env=DRONE_GITLAB_CLIENT_ID=492d4ca593a450d8216ed124a8e94b5dffb4f95845c7ca163455da74519f51cf \
  --env=DRONE_GITLAB_CLIENT_SECRET=29161ed6b2a420325c0477856372bf2313470d3dea8d5ed24e7401822aa6c71f \
  --env=DRONE_RPC_SECRET=631ab7819e58a05f1bd2abe8253751ba \
  --env=DRONE_SERVER_HOST=10.200.75.213 \
  --env=DRONE_SERVER_PROTO=http \
	--env=DRONE_USER_CREATE=username:root,admin:true \
	-e TZ="Asia/Shanghai" \
  --publish=80:80 \
  --publish=443:443 \
  --restart=always \
  --detach=true \
  --name=drone \
  drone/drone:2
```


```
--env=DRONE_USER_CREATE=username:yourUsername,admin:true 这行非常关键，加上之后，使用 yourUsername 用户名登录 drone 便成为了管理员，如果不加，则看不到Trusted那个按钮。
```


###  准备 drone-runner 的docker
```
docker pull drone/drone-runner-docker:1
```


### 


|-|-|
|---|---|
|DRONE_RPC_HOST | 提供 Drone 服务器的主机名（和可选端口）。 运行器连接到主机地址处的服务器以接收管道以供执行。 |
|DRONE_RPC_PROTO |提供用于连接到您的 Drone 服务器的协议。 该值必须是 http 或 https。 |
|DRONE_RPC_SECRET|提供用于与您的 Drone 服务器进行身份验证的共享密钥。 这必须与您的 Drone 服务器配置中定义的秘密相匹配|

### 运行 drone-runner

- 例子
```
docker run --detach \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --env=DRONE_RPC_PROTO=https \
  --env=DRONE_RPC_HOST=drone.company.com \
  --env=DRONE_RPC_SECRET=super-duper-secret \
  --env=DRONE_RUNNER_CAPACITY=2 \
  --env=DRONE_RUNNER_NAME=my-first-runner \
  --publish=3000:3000 \
  --restart=always \
  --name=runner \
  drone/drone-runner-docker:1

```

- 实例

```
docker run --detach \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --env=DRONE_RPC_PROTO=http \
  --env=DRONE_RPC_HOST=10.200.75.213 \
  --env=DRONE_RPC_SECRET=631ab7819e58a05f1bd2abe8253751ba \
  --env=DRONE_RUNNER_CAPACITY=2 \
  --env=DRONE_RUNNER_NAME=my-first-runner \
  --publish=3000:3000 \
  --restart=always \
  --name=runner \
  drone/drone-runner-docker:1
```

### 验证
```
docker logs runner

INFO[0000] starting the server
INFO[0000] successfully pinged the remote server 
```