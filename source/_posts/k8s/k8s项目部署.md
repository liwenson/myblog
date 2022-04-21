---
title: k8s项目部署流程
date: 2022-01-17 15:46
categories:
- k8s
tags:
- ci/cd
---
  
  
摘要: 使用Jenkins和GitOps实现CI/CD。
<!-- more -->

[toc]


## 软件部署
[k8s yaml部署地址](https://github.com/cool-ops/kubernetes-software-yaml.git)


|软件	|版本|
|---|---|
|kubernetes|	1.17.9|
|docker	|19.03.13|
|jenkins|	2.249.3|
|argocd	|1.8.0|
|gitlab	|社区版11.8.1|
|sonarqube|	社区版8.5.1|
|Dependency-Track| |
|traefik	|2.3.3|

### namespace 
操作都在 jenins-ns 命名空间下进行
#### 命名空间创建
```
vim namespace.yaml

---
apiVersion: v1
kind: Namespace
metadata:
  name: jenkins-ns
```

### 部署nfs
#### 安装nfs服务
略
#### 部署 k8s-nfs-storageClass动态供给

nfs-rbac.yaml
```
vim nfs-rbac.yaml


---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  namespace: jenkins-ns
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
   name: nfs-provisioner-runner
   namespace: jenkins-ns
rules:
   -  apiGroups: [""]
      resources: ["persistentvolumes"]
      verbs: ["get", "list", "watch", "create", "delete"]
   -  apiGroups: [""]
      resources: ["persistentvolumeclaims"]
      verbs: ["get", "list", "watch", "update"]
   -  apiGroups: ["storage.k8s.io"]
      resources: ["storageclasses"]
      verbs: ["get", "list", "watch"]
   -  apiGroups: [""]
      resources: ["events"]
      verbs: ["watch", "create", "update", "patch"]
   -  apiGroups: [""]
      resources: ["services", "endpoints"]
      verbs: ["get","create","list", "watch","update"]
   -  apiGroups: ["extensions"]
      resources: ["podsecuritypolicies"]
      resourceNames: ["nfs-provisioner"]
      verbs: ["use"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: jenkins-ns
roleRef:
  kind: ClusterRole
  name: nfs-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
```

nfs-storageclass.yaml
```
vim nfs-storageclass.yaml

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-sc
  namespace: jenkins-ns
provisioner: test-nfs-storage
reclaimPolicy: Retain
```

nfs-deployment.yaml 
```
vim  nfs-deployment.yaml 

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: jenkins-ns  #与RBAC文件中的namespace保持一致
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: quay.io/external_storage/nfs-client-provisioner:latest
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: test-nfs-storage  #provisioner名称,请确保该名称与 nfs-StorageClass.yaml文件中的provisioner名称保持一致
            - name: NFS_SERVER
              value: 10.200.75.127   #NFS Server IP地址
            - name: NFS_PATH  
              value: /data/k8s    #NFS挂载卷
      volumes:
        - name: nfs-client-root
          nfs:
            server: 10.200.75.127    #NFS Server IP地址
            path: /data/k8s


```

### 部署jenkins

rbac.yaml

```
vim jenkins-rbac.yaml


---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins-sa
  namespace: jenkins-ns

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
   name: jenkins-cr
   namespace: jenkins-ns
rules:
  - apiGroups: ["extensions", "apps"]
    resources: ["deployments"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get","list","watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: jenkins-crd
roleRef:
  kind: ClusterRole
  name: jenkins-cr
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: jenkins-sa
  namespace: jenkins-ns
```

storageclass.yaml
```
vim jenkins-storageclass.yaml

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-pvc
  namespace: jenkins-ns
spec:
  storageClassName: nfs-sc
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi

```


### jenkins配置
#### 插件安装
```
kubernetes
AnsiColor
HTTP Request
SonarQube Scanner
Utility Steps
Email Extension Template
Gitlab Hook
Gitlab
OWASP Dependency-Track
DingTalk
build user vars
```

#### 配置Kubernetes集群信息

##### 安全配置
系统管理 --> 全局安全配置 --> TCP port for inbound agents --> Fixed:50000

##### Dependency-Track配置
系统管理 --> Dependency-Track --> Dependency-Track URL --> API key --> Auto Create Projects

##### 钉钉配置
系统管理 --> 系统配置 --> 钉钉


##### k8s 配置
系统管理 --> 系统配置 --> cloud


```
http://JENKINSURL/configureClouds/
```

```
k8s 信息

kubernetes 名称:  kubernetes
kubernetes 地址:  http://10.200.92.60:8080/   # k8s api地址
kubernetes 命名空间:  jenkins-ns
jenins 地址:   http://10.200.92.60:30002/     # jenkins 地址
```

#### credentials配置
```
配置 gitlab 凭证
配置 harbor 凭证
配置 Dependency-Track 凭证
配置 SonarQube 凭证
```


## 准备测试代码
```
https://github.com/gazgeek/springboot-helloworld
```
```
mvn clean install
java -jar target/helloworld-0.0.1-SNAPSHOT.jar

http://localhost:8080/
```

```
https://blog.horus-k.com
```


## 准备jenkins共享库

首先在gitlab上创建一个共享库，我这里取名叫 shareLibrary
然后创建 src/org/devops 目录，并在该目录下创建一下文件。
```
mkdir -p src/org/devops
cd src/org/devops
touch build.groovy
touch sendEmail.groovy
touch sonarAPI.groovy
touch sonarqube.groovy
touch tools.groovy
```

cat build.groovy
```
package org.devops

// docker容器直接build
def DockerBuild(buildShell){
    sh """
        ${buildShell}
    """
}
```
cat sendEmail.groovy
```
package org.devops

//定义邮件内容
def SendEmail(status,emailUser){
    emailext body: """
            <!DOCTYPE html> 
            <html> 
            <head> 
            <meta charset="UTF-8"> 
            </head> 
            <body leftmargin="8" marginwidth="0" topmargin="8" marginheight="4" offset="0"> 
                <table width="95%" cellpadding="0" cellspacing="0" style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">   
                <tr>
                    本邮件由系统自动发出，无需回复！<br/>
                    各位同事，大家好，以下为${JOB_NAME}项目构建信息</br>
                    <td><font color="#CC0000">构建结果 - ${status}</font></td>
                </tr>

                    <tr> 
                        <td><br /> 
                            <b><font color="#0B610B">构建信息</font></b> 
                        </td> 
                    </tr> 
                    <tr> 
                        <td> 
                            <ul> 
                                <li>项目名称：${JOB_NAME}</li>         
                                <li>构建编号：${BUILD_ID}</li> 
                                <li>构建状态: ${status} </li>                         
                                <li>项目地址：<a href="${BUILD_URL}">${BUILD_URL}</a></li>    
                                <li>构建日志：<a href="${BUILD_URL}console">${BUILD_URL}console</a></li>   
                            </ul> 
                        </td> 
                    </tr> 
                    <tr>  
                </table> 
            </body> 
            </html>  """,
            subject: "Jenkins-${JOB_NAME}项目构建信息 ",
            to: emailUser
}
```
cat sonarAPI.groovy
```
package ore.devops

// 封装HTTP请求
def HttpReq(requestType,requestUrl,requestBody){
    // 定义sonar api接口
    def sonarServer = "http://sonar.devops.svc.cluster.local:9000/api"
    result = httpRequest authentication: 'sonar-admin-user',
            httpMode: requestType,
            contentType: "APPLICATION_JSON",
            consoleLogResponseBody: true,
            ignoreSslErrors: true,
            requestBody: requestBody,
            url: "${sonarServer}/${requestUrl}"
    return result
}

// 获取soanr项目的状态
def GetSonarStatus(projectName){
    def apiUrl = "project_branches/list?project=${projectName}"
    // 发请求
    response = HttpReq("GET",apiUrl,"")
    // 对返回的文本做JSON解析
    response = readJSON text: """${response.content}"""
    // 获取状态值
    result = response["branches"][0]["status"]["qualityGateStatus"]
    return result
}

// 获取sonar项目，判断项目是否存在
def SearchProject(projectName){
    def apiUrl = "projects/search?projects=${projectName}"
    // 发请求
    response = HttpReq("GET",apiUrl,"")
    println "搜索的结果：${response}"
    // 对返回的文本做JSON解析
    response = readJSON text: """${response.content}"""
    // 获取total字段，该字段如果是0则表示项目不存在,否则表示项目存在
    result = response["paging"]["total"]
    // 对result进行判断
    if (result.toString() == "0"){
        return "false"
    }else{
        return "true"
    }
}

// 创建sonar项目
def CreateProject(projectName){
    def apiUrl = "projects/create?name=${projectName}&project=${projectName}"
    // 发请求
    response = HttpReq("POST",apiUrl,"")
    println(response)
}

// 配置项目质量规则
def ConfigQualityProfiles(projectName,lang,qpname){
    def apiUrl = "qualityprofiles/add_project?language=${lang}&project=${projectName}&qualityProfile=${qpname}"
    // 发请求
    response = HttpReq("POST",apiUrl,"")
    println(response)
}

// 获取质量阈ID
def GetQualityGateId(gateName){
    def apiUrl = "qualitygates/show?name=${gateName}"
    // 发请求
    response = HttpReq("GET",apiUrl,"")
    // 对返回的文本做JSON解析
    response = readJSON text: """${response.content}"""
    // 获取total字段，该字段如果是0则表示项目不存在,否则表示项目存在
    result = response["id"]
    return result
}

// 更新质量阈规则
def ConfigQualityGate(projectKey,gateName){
    // 获取质量阈id
    gateId = GetQualityGateId(gateName)
    apiUrl = "qualitygates/select?projectKey=${projectKey}&gateId=${gateId}"
    // 发请求
    response = HttpReq("POST",apiUrl,"")
    println(response)
}

//获取Sonar质量阈状态
def GetProjectStatus(projectName){
    apiUrl = "project_branches/list?project=${projectName}"
    response = HttpReq("GET",apiUrl,'')
    
    response = readJSON text: """${response.content}"""
    result = response["branches"][0]["status"]["qualityGateStatus"]
    
    //println(response)
    
   return result
}
```

cat sonarqube.groovy
```
package ore.devops

def SonarScan(projectName,projectDesc,projectPath){
    // sonarScanner安装地址
    def sonarHome = "/opt/sonar-scanner"
    // sonarqube服务端地址
    def sonarServer = "http://sonar.devops.svc.cluster.local:9000/"
    // 以时间戳为版本
    def scanTime = sh returnStdout: true, script: 'date +%Y%m%d%H%m%S'
    scanTime = scanTime - "\n"
    sh """
    ${sonarHome}/bin/sonar-scanner  -Dsonar.host.url=${sonarServer}  \
    -Dsonar.projectKey=${projectName}  \
    -Dsonar.projectName=${projectName}  \
    -Dsonar.projectVersion=${scanTime} \
    -Dsonar.login=admin \
    -Dsonar.password=admin \
    -Dsonar.ws.timeout=30 \
    -Dsonar.projectDescription="${projectDesc}"  \
    -Dsonar.links.homepage=http://www.baidu.com \
    -Dsonar.sources=${projectPath} \
    -Dsonar.sourceEncoding=UTF-8 \
    -Dsonar.java.binaries=target/classes \
    -Dsonar.java.test.binaries=target/test-classes \
    -Dsonar.java.surefire.report=target/surefire-reports -X 

    echo "${projectName}  scan success!"
    """
}
```

cat tools.groovy
```
package org.devops

//格式化输出
def PrintMes(value,color){
    colors = ['red'   : "\033[40;31m >>>>>>>>>>>${value}<<<<<<<<<<< \033[0m",
              'blue'  : "\033[47;34m ${value} \033[0m",
              'green' : "[1;32m>>>>>>>>>>${value}>>>>>>>>>>[m",
              'green1' : "\033[40;32m >>>>>>>>>>>${value}<<<<<<<<<<< \033[0m" ]
    ansiColor('xterm') {
        println(colors[color])
    }
}


// 获取镜像版本
def createVersion() {
    // 定义一个版本号作为当次构建的版本，输出结果 20191210175842_69
    return new Date().format('yyyyMMddHHmmss') + "_${env.BUILD_ID}"
}


// 获取时间
def getTime() {
    // 定义一个版本号作为当次构建的版本，输出结果 20191210175842
    return new Date().format('yyyyMMddHHmmss')
}
```

### jenkins 配置共享库
略

## jenkins 创建pipeline JOB

### 简单测试jenkinsfile
```
def labels = "slave-${UUID.randomUUID().toString()}"
// 引用共享库
@Library("jenkins_shareLibrary")

// 应用共享库中的方法
def tools = new org.devops.tools()

pipeline {
    agent {
    kubernetes {
        label labels
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: some-label-value
spec:
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
      type: ''
  containers:
  - name: jnlp
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/inbound-agent:4.3-4
  - name: maven
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/maven:3.5.0-alpine
    command:
    - cat
    tty: true
  - name: docker
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/docker:19.03.11
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
"""
    }
  }
    stages {
        stage('Checkout') {
            steps {
                script{
                    tools.PrintMes("拉代码","green")
                }
            }
        }
        stage('Build') {
            steps {
                container('maven') {
                    script{
                        tools.PrintMes("编译打包","green")
                    }
                }
            }
        }
        stage('Make Image') {
            steps {
                container('docker') {
                    script{
                        tools.PrintMes("构建镜像","green")
                    }
                }
            }
        }
    }
}
```
然后点击保存并运行，如果看到输出有颜色，就代表共享库配置成功


### 编写Jenkinsfile
```
1、创建jenkins-slave,分配任务到slave执行
2、git下载代码
3、源代码规范和源代码安全扫描
4、mvn 编译二进制文件
5、jar 包安全扫描
6、生成dockerfile 配置文件
7、生成kubernetes 配置文件
8、制作docker镜像并上传到镜像仓库
9、docker镜像安全扫描
10、发布到kubernetes 集群
```

```
def labels = "slave-${UUID.randomUUID().toString()}"

// 引用共享库
@Library("jenkins_shareLibrary")

// 应用共享库中的方法
def tools = new org.devops.tools()
def sonarapi = new org.devops.sonarAPI()
def sendEmail = new org.devops.sendEmail()
def build = new org.devops.build()
def sonar = new org.devops.sonarqube()

// 前端传来的变量
def gitBranch = env.branch
def gitUrl = env.git_url
def buildShell = env.build_shell
def image = env.image
def dockerRegistryUrl = env.dockerRegistryUrl
def devops_cd_git = env.devops_cd_git


pipeline {
    agent {
    kubernetes {
        label labels
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: some-label-value
spec:
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
      type: ''
  - name: maven-cache
    persistentVolumeClaim:
      claimName: maven-cache-pvc
  containers:
  - name: jnlp
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/inbound-agent:4.3-4
  - name: maven
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/maven:3.5.0-alpine
    command:
    - cat
    tty: true
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  - name: docker
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/docker:19.03.11
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: sonar-scanner
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/sonar-scanner:latest
    command:
    - cat
    tty: true
  - name: kustomize
    image: registry.cn-hangzhou.aliyuncs.com/rookieops/kustomize:v3.8.1
    command:
    - cat
    tty: true
"""
    }
  }

    environment{
        auth = 'joker'
    }

    options {
        timestamps()    // 日志会有时间
        skipDefaultCheckout()   // 删除隐式checkout scm语句
        disableConcurrentBuilds()   //禁止并行
        timeout(time:1,unit:'HOURS') //设置流水线超时时间
    }


    stages {
        // 拉取代码
        stage('GetCode') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: "${gitBranch}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [],
                    submoduleCfg: [],
                    userRemoteConfigs: [[credentialsId: '83d2e934-75c9-48fe-9703-b48e2feff4d8', url: "${gitUrl}"]]])
                }
            }

        // 单元测试和编译打包
        stage('Build&Test') {
            steps {
                container('maven') {
                    script{
                        tools.PrintMes("编译打包","blue")
                        build.DockerBuild("${buildShell}")
                    }
                }
            }
        }
        // 代码扫描
        stage('CodeScanner') {
            steps {
                container('sonar-scanner') {
                    script {
                        tools.PrintMes("代码扫描","green")
                        tools.PrintMes("搜索项目","green")
                        result = sonarapi.SearchProject("${JOB_NAME}")
                        println(result)

                        if (result == "false"){
                            println("${JOB_NAME}---项目不存在,准备创建项目---> ${JOB_NAME}！")
                            sonarapi.CreateProject("${JOB_NAME}")
                        } else {
                            println("${JOB_NAME}---项目已存在！")
                        }

                        tools.PrintMes("代码扫描","green")
                        sonar.SonarScan("${JOB_NAME}","${JOB_NAME}","src")

                        sleep 10
                        tools.PrintMes("获取扫描结果","green")
                        result = sonarapi.GetProjectStatus("${JOB_NAME}")

                        println(result)
                        if (result.toString() == "ERROR"){
                            toemail.Email("代码质量阈错误！请及时修复！",userEmail)
                            error " 代码质量阈错误！请及时修复！"

                        } else {
                            println(result)
                        }
                    }
                }
            }
        }
        stage('dependencyTrackPublisher') {
            steps {
                withCredentials([string(credentialsId: 'dependencytrack', variable: "API_KEY")]) {
                    dependencyTrackPublisher artifact: 'target/bom.xml', projectName: "${JOB_NAME}",projectVersion: "${BUILD_NUMBER}", synchronous: true, dependencyTrackApiKey: "$API_KEY"
                }
            }
        }

        // 构建镜像
        stage('BuildImage') {
            steps {
                withCredentials([[$class: 'UsernamePasswordMultiBinding',
                credentialsId: 'dockerhub',
                usernameVariable: 'DOCKER_HUB_USER',
                passwordVariable: 'DOCKER_HUB_PASSWORD']]) {
                    container('docker') {
                        script{
                            tools.PrintMes("构建镜像","green")
                            imageTag = tools.createVersion()
                            sh """
                            docker login ${dockerRegistryUrl} -u ${DOCKER_HUB_USER} -p ${DOCKER_HUB_PASSWORD}
                            docker build -t ${image}:${imageTag} .
                            docker push ${image}:${imageTag}
                            docker rmi ${image}:${imageTag}
                            """
                        }
                    }
                }
            }
        }
        // 部署
        stage('Deploy') {
            steps {
                 withCredentials([[$class: 'UsernamePasswordMultiBinding',
                credentialsId: 'ci-devops',
                usernameVariable: 'DEVOPS_USER',
                passwordVariable: 'DEVOPS_PASSWORD']]){
                    container('kustomize') {
                        script{
                            APP_DIR="${JOB_NAME}".split("_")[0]
                            sh """
                            git remote set-url origin http://${DEVOPS_USER}:${DEVOPS_PASSWORD}@${devops_cd_git}
                            git config --global user.name "Administrator"
                            git config --global user.email "coolops@163.com"
                            git clone http://${DEVOPS_USER}:${DEVOPS_PASSWORD}@${devops_cd_git} /opt/devops-cd
                            cd /opt/devops-cd
                            git pull
                            cd /opt/devops-cd/${APP_DIR}
                            kustomize edit set image ${image}:${imageTag}
                            git commit -am 'image update'
                            git push origin master
                            """
                        }
                    }
                }
            }
        }
        // 接口测试
        stage('InterfaceTest') {
            steps{
                sh 'echo "接口测试"'
            }
        }
    }
    // 构建后的操作
    post {
        success {
            script{
                println("success:只有构建成功才会执行")
                currentBuild.description += "\n构建成功！"
                // deploy.AnsibleDeploy("${deployHosts}","-m ping")
                sendEmail.SendEmail("构建成功",toEmailUser)
                // dingmes.SendDingTalk("构建成功 ✅")
            }
        }
        failure {
            script{
                println("failure:只有构建失败才会执行")
                currentBuild.description += "\n构建失败!"
                sendEmail.SendEmail("构建失败",toEmailUser)
                // dingmes.SendDingTalk("构建失败 ❌")
            }
        }
        aborted {
            script{
                println("aborted:只有取消构建才会执行")
                currentBuild.description += "\n构建取消!"
                sendEmail.SendEmail("取消构建",toEmailUser)
                // dingmes.SendDingTalk("构建失败 ❌","暂停或中断")
            }
        }
    }
}
```

