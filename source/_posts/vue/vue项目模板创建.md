---
title: vue项目模板创建
date: 2021-12-06 14:19
categories:
- vue
tags:
- vue
---
  
  
摘要: vue 项目模板创建
<!-- more -->


## 目录说明


|目录| 说明|
|---|---|
|node_modules  |项目依赖模块包|
|src | 源代码目录|
|public|存放静态文件|
|src -> api | 全局接口目录，应与views目录对应|
|src -> assets|静态文件目录|
|src -> componets|全局组件目录|
|src -> filters|全局过滤器目录|
|src -> router|路由目录|
|src -> store|状态管理目录|
|src -> utils|工具目录|
|src -> views|页面目录，应与api目录对应|
|src -> App.vue|主页面|
|src -> main.js|入口文件|
|.env.development|开发环境配置文件|
|.env.production | 正式环境配置文件|
|.env.test|测试环境配置文件|
|.gitignore|git忽略配置文件|
|babel.config.js|babel配置文件|
|package-lock.json|-|
|package.json|依赖配置文件|
|README.md|说明文件|
|vue.config.js|项目配置文件



## 创建vue2 项目
选择vue2 项目创建
```
vue create myapp

Vue CLI v4.5.15
? Please pick a preset: (Use arrow keys)
❯ Default ([Vue 2] babel, eslint) 
  Default (Vue 3) ([Vue 3] babel, eslint) 
  Manually select features


Vue CLI v4.5.15
? Please pick a preset: Default ([Vue 2] babel, eslint)


Vue CLI v4.5.15
✨  Creating project in /workspaces/vue/myapp02.
🗃  Initializing git repository...
⚙️  Installing CLI plugins. This might take a while...

yarn install v1.22.15
info No lockfile found.
[1/4] Resolving packages...
[2/4] Fetching packages...
info fsevents@2.3.2: The platform "linux" is incompatible with this module.
info "fsevents@2.3.2" is an optional dependency and failed compatibility check. Excluding it from installation.
info fsevents@1.2.13: The platform "linux" is incompatible with this module.
info "fsevents@1.2.13" is an optional dependency and failed compatibility check. Excluding it from installation.


success Saved lockfile.
Done in 145.72s.
🚀  Invoking generators...
📦  Installing additional dependencies...

yarn install v1.22.15
[1/4] Resolving packages...
[2/4] Fetching packages...
info fsevents@2.3.2: The platform "linux" is incompatible with this module.
info "fsevents@2.3.2" is an optional dependency and failed compatibility check. Excluding it from installation.
info fsevents@1.2.13: The platform "linux" is incompatible with this module.
info "fsevents@1.2.13" is an optional dependency and failed compatibility check. Excluding it from installation.
[3/4] Linking dependencies...

success Saved lockfile.
Done in 130.34s.
⚓  Running completion hooks...

📄  Generating README.md...

🎉  Successfully created project myapp02.
👉  Get started with the following commands:

 $ cd myapp
 $ yarn serve

```

## axios的封装和使用

在项目里面对axios封装能够节省不少的代码和时间，首先在 src -> utils 目录下新建 request.js 文件
```
// src -> utils > request.js文件
 
import axios from "axios";
import { Message } from "element-ui";
 
const service = axios.create({
  baseURL: process.env.VUE_APP_BASE_URL,
  timeout: 0
});
 
service.interceptors.request.use(
  config => {
    //如果本地存储里有JSESSIONID就携带上去，一般是自己登录后存进去的
    const JSESSIONID = sessionStorage.getItem("JSESSIONID");
    if (JSESSIONID) {
      config.headers["JSESSIONID"] = JSESSIONID;
    }
    return config;
  },
  error => {
    Promise.reject(error);
  }
);
 
service.interceptors.response.use(
  response => {
    const res = response.data;
    //此处的值自己与后台约定
    if (res._code != "200") {
      Message.closeAll();
      Message({
        message: res._msg,
        type: "error",
        duration: 3 * 1000
      });
      return Promise.reject(res);
    } else {
      return res;
    }
  },
  error => {
    var status;
    try {
      status = error.response.status;
    } catch (error) {
      //解决跨域等问题的错误下获取不到status
      Message.closeAll();
      Message({
        message: "服务器未知错误",
        type: "error",
        duration: 3 * 1000
      });
      return Promise.reject(error);
    }
    let msg = "";
    switch (status) {
      case 400:
        msg = "错误的请求";
        break;
        ...
      default:
        msg = "连接错误";
        break;
    }
    Message.closeAll();
    Message({
      message: status + msg,
      type: "error",
      duration: 3 * 1000
    });
    return Promise.reject(error);
  }
);
export default service;
```

