---
title: Argo CD 进行 GitOps 实践
date: 2021-10-12 14:21
categories:
- k8s
tags:
- argo
---
	
	
摘要: Argo CD 进行 GitOps 实践

参考文章： https://www.qikqiak.com/post/gitlab-ci-argo-cd-gitops/
<!-- more -->


## 安装k8s 
一键部署脚本
```
https://gitee.com/q7104475/K8s
```

## 通过kubeapp 部署argocd 
Argo CD 是一个声明式、GitOps 持续交付的 Kubernetes 工具，它的配置和使用分非常简单，并且自带一个简单一用的 Dashboard 页面，更重要的是 Argo CD 支持 kustomzie、helm、ksonnet 等多种工具。应用程序可以通过 Argo CD 提供的 CRD 资源对象进行配置，可以在指定的目标环境中自动部署所需的应用程序。关于 Argo CD 更多的信息可以查看官方文档了解更多。
```
k8s应用商店kubeapps地址:  http://IP:30082
登录token获取命令: sh /root/K8s/k8s_yaml/get_kubeapps_token.sh 
```
登陆之后通过搜索仓库，找到argocd 然后部署。

获取安装完成之后的登陆密码
```
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.clearPassword}" | base64 -d)"
```

## GitLab 项目配置

我们这里使用的示例项目是一个 Golang 程序，在页面上显示一个文本信息和 Pod 名称，代码地址：http://172.16.100.85:3000/root/gitops-webapp-example.git。

接下来需要添加一些在 GitLab CI 流水线中用到的环境变量<br/>
Settings → CI/CD → Variables

    CI_REGISTRY   -    镜像仓库地址，值为：https://index.docker.io/v1/
    CI_REGISTRY_IMAGE   -   镜像名称，值为：cnych/gitops-webapp
    CI_REGISTRY_USER    -   Docker Hub 仓库用户名，值为 cnych
    CI_REGISTRY_PASSWORD    -   Docker Hub 仓库密码
    CI_GIT_PASSWORD   -  Git 仓库访问密码
    CI_GIT_USERNAME    -  Git 仓库访问用户名



## Argo CD 配置

现在我们可以开始使用 GitOps 来配置我们的 Kubernetes 中的应用了。Argo CD 自带了一套 CRD 对象，可以用来进行声明式配置，这当然也是推荐的方式，把我们的基础设施作为代码来进行托管，下面是我们为开发和生产两套环境配置的资源清单：
```
# gitops-demo-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app-dev
  namespace: argocd
spec:
  project: default
  source: 
    repoURL: http://172.16.100.85:3000/root/gitops-webapp-example.git
    targetRevision: HEAD
    path: deployment/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app-prod
  namespace: argocd
spec:
  project: default
  source: 
    repoURL: http://172.16.100.85:3000/root/gitops-webapp-example.git
    targetRevision: HEAD
    path: deployment/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: true
```

上面定义的 Application 这个资源，就是 Argo CD 用于描述应用的 CRD 对象：

    name：Argo CD 应用程序的名称
    project：应用程序将被配置的项目名称，这是在 Argo CD 中应用程序的一种组织方式
    repoURL：源代码的仓库地址
    targetRevision：想要使用的 git 分支
    path：Kubernetes 资源清单在仓库中的路径
    destination：Kubernetes 集群中的目标

然后同样使用 kubectl 工具直接部署上面的资源对象即可，将会创建两个 Application 类型的对象：
```
$ kubectl apply -f gitops-demo-app.yaml
application.argoproj.io/web-app-dev created
application.argoproj.io/web-app-prod created
$ kubectl get application -n argocd
NAME           AGE
web-app-dev    25s
web-app-prod   24s
```

此时我们再去 Argo CD 的 Dashboard 首页同样将会看到两个 Application 的信息。

点击其中一个就可以看到关于应用的详细信息，我们可以在 gitops-webapp-example 代码仓库的 deployment/<env> 目录里面找到资源对象。我们可以看到，在每个文件夹下面都有一个 kustomization.yaml 文件，Argo CD 可以识别它，不需要任何其他的设置就可以使用。

由于我们这里的代码仓库是私有的 GitLab，所以我们还需要配置对应的仓库地址，在页面上 Settings → Repositories，点击 Connect Repo using HTTPS 添加我们的代码仓库认证信息。

需要注意的是这里默认使用的是 HTTPS，所以我们需要勾选下方的 Skip server verification，然后点击上方的 CONNECT 按钮添加即可。然后重新同步上面的两个 Application，就可以看到正常的状态了。


## GitLab CI 流水线

接下来我们需要为应用程序创建流水线，自动构建我们的应用程序，推送到镜像仓库，然后更新 Kubernetes 的资源清单文件。

下面的示例并不是一个多么完美的流水线，但是基本上可以展示整个 GitOps 的工作流。开发人员在自己的分支上开发代码，他们分支的每一次提交都会触发一个阶段性的构建，当他们将自己的修改和主分支合并时，完整的流水线就被触发。将构建应用程序，打包成 Docker 镜像，将镜推送到 Docker 仓库，并自动更新 Kubernetes 资源清单，此外，一般情况下将应用部署到生产环境需要手动操作。
GitLab CI 中的流水线默认定义在代码仓库根目录下的 .gitlab-ci.yml 文件中，在改文件的最上面定义了一些构建阶段和环境变量、镜像以及一些前置脚本：
```
stages:
- build
- publish
- deploy-dev
- deploy-prod
```

接下来是阶段的定义和所需的任务声明。我们这里的构建过程比较简单，只需要在一个 golang 镜像中执行一个构建命令即可，然后将编译好的二进制文件保存到下一个阶段处理，这一个阶段适合分支的任何变更：
```
build:
  stage: build
  image:
    name: golang:1.13.1
  script:
    - go build -o main main.go
  artifacts:
    paths:
      - main
  variables:
    CGO_ENABLED: 0
```

然后就是构建镜像并推送到镜像仓库，这里我们使用 Kaniko，当然也可以使用 DinD 模式进行构建，只是安全性不高，这里我们可以使用 GIT 提交的 commit 哈希值作为镜像 tag，关于 Docker 镜像仓库的认证和镜像地址信息可以通过项目的参数来进行传递，不过这个阶段只在主分支发生变化时才会触发：
```
publish:
  stage: publish
  image:
    name: cnych/kaniko-executor:v0.22.0
    entrypoint: [""]
  script:
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile ./Dockerfile --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  dependencies:
    - build  
  only:
    - master
```
下一个阶段就是将应用程序部署到开发环境中，在 GitOps 中就意味着需要更新 Kubernetes 的资源清单，这样 Argo CD 就可以拉取更新的版本来部署应用。这里我们使用了为项目定义的环境变量，包括用户名和 TOKEN，此外在提交消息里面增加 [skip ci] 这样的关键字，这样流水线就不会被触发：
```
deploy-dev:
  stage: deploy-dev
  image: cnych/kustomize:v1.0
  before_script:
    - git remote set-url origin http://${CI_USERNAME}:${CI_PASSWORD}@git.k8s.local/course/gitops-webapp.git
    - git config --global user.email "gitlab@git.k8s.local"
    - git config --global user.name "GitLab CI/CD"
  script:
    - git checkout -B master
    - cd deployment/dev
    - kustomize edit set image $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - cat kustomization.yaml
    - git commit -am '[skip ci] DEV image update'
    - git push origin master
  only:
    - master
```

最后添加一个部署到 prod 环境的阶段，和前面非常类似，只是添加了一个手动操作的流程：
```
deploy-prod:
  stage: deploy-prod
  image: cnych/kustomize:v1.0
  before_script:
    - git remote set-url origin http://${CI_USERNAME}:${CI_PASSWORD}@git.k8s.local/course/gitops-webapp.git
    - git config --global user.email "gitlab@git.k8s.local"
    - git config --global user.name "GitLab CI/CD"
  script:
    - git checkout -B master
    - git pull origin master
    - cd deployment/prod
    - kustomize edit set image $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    - cat kustomization.yaml
    - git commit -am '[skip ci] PROD image update'
    - git push origin master
  only:
    - master
  when: manual
```


## Ingress

```
vim mandatory.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---

kind: ConfigMap
apiVersion: v1
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: tcp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: udp-services
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-serviceaccount
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: nginx-ingress-clusterrole
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
      - "networking.k8s.io"
    resources:
      - ingresses/status
    verbs:
      - update

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: nginx-ingress-role
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - pods
      - secrets
      - namespaces
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    resourceNames:
      # Defaults to "<election-id>-<ingress-class>"
      # Here: "<ingress-controller-leader>-<nginx>"
      # This has to be adapted if you change either parameter
      # when launching the nginx-ingress-controller.
      - "ingress-controller-leader-nginx"
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: nginx-ingress-role-nisa-binding
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-ingress-role
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: nginx-ingress-clusterrole-nisa-binding
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nginx-ingress-clusterrole
subjects:
  - kind: ServiceAccount
    name: nginx-ingress-serviceaccount
    namespace: ingress-nginx

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/part-of: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
      annotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
    spec:
      hostNetwork: true
      # wait up to five minutes for the drain of connections
      terminationGracePeriodSeconds: 300
      serviceAccountName: nginx-ingress-serviceaccount
      nodeSelector:
        kubernetes.io/os: linux
      containers:
        - name: nginx-ingress-controller
          image: quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.29.0
          args:
            - /nginx-ingress-controller
            - --configmap=$(POD_NAMESPACE)/nginx-configuration
            - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
            - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx
            - --annotations-prefix=nginx.ingress.kubernetes.io
          securityContext:
            allowPrivilegeEscalation: true
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            # www-data -> 101
            runAsUser: 101
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
            - name: https
              containerPort: 443
              protocol: TCP
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 10
          lifecycle:
            preStop:
              exec:
                command:
                  - /wait-shutdown

---

apiVersion: v1
kind: LimitRange
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  limits:
  - min:
      memory: 90Mi
      cpu: 100m
    type: Container

```

创建
```
kubectl apply -f mandatory.yaml
```

配置DNS解析，或者直接修改client的hosts文件。就可以访问到页面了
```
通过命令 kubectl get pod -n ingress-nginx -o wide 可以查看Ingress-nginx容器所在节点的IP
```

虽然访问到了对应的服务，但是有一个弊端，就是在做DNS解析的时候，只能指定Ingress-nginx容器所在的节点IP。而指定k8s集群内部的其他节点IP（包括master）都是不可以访问到的，如果这个节点一旦宕机，Ingress-nginx容器被转移到其他节点上运行（不考虑节点标签的问题，其实保持Ingress-nginx的yaml文件中默认的标签的话，那么每个节点都是有那个标签的）。随之还要我们手动去更改DNS解析的IP


## Ingress-controller资源对象创建一个service资源对象
```
vim service-nodeport.yaml


apiVersion: v1
kind: Service
metadata:
  name: ingress-nginx
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
spec:
  type: NodePort
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
    - name: https
      port: 443
      targetPort: 443
      protocol: TCP
  selector:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx

---

```

创建
```
kubectl apply -f service-nodeport.yaml

kubectl get svc -n ingress-nginx
```


