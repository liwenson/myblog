---
title: hexo主题开发
date: 2022-02-24 16:59
categories:
- hexo
tags:
- hexo
---
  
  
摘要: hexo主题开发
<!-- more -->

## 参考文章
```
https://liuyib.github.io/2019/08/20/develop-hexo-theme-from-0-to-1/

https://easyhexo.com/4-High-order-hexo-gamer/4-2-theme-develop/#%E5%89%8D%E8%A8%80

https://www.cnblogs.com/yyhh/p/11058985.html
```

## 知识储备

### 模板引擎
常用的几种模板引擎有：Swig、EJS、Haml 或 Jade。其中 Jade 由于商标问题，改名为 Pug，虽然它们是兼容的，但使用的时候，推荐安装 Pug 而不是 Jade。Hexo 内置了 Swig，将文件扩展名改为 .swig 即可使用，你也可以安装插件来获得另外几种模板引擎的支持，Hexo 会根据文件扩展名来决定使用哪一种。例如：
```
layout.pug   -- 使用 pug
layout.swig  -- 使用 swig
```

选择一个自己喜欢的模板引擎，然后浏览文档，了解这个模板引擎的基本用法。

- 英文文档地址分别如下：[Swig](https://node-swig.github.io/swig-templates/docs/)、[EJS](https://ejs.co/#docs)、[Pug](https://pugjs.org/api/getting-started.html)、[Haml](http://haml.info/docs.html)。
- 中文文档地址分别如下：[Swig](https://myvin.github.io/swig.zh-CN/docs/index.html)、[EJS](https://ejs.bootcss.com/#docs)、[Pug](https://pugjs.org/zh-cn/api/getting-started.html)、[Haml]()（无）。

### CSS预处理语言

常见的 CSS 预处理语言有：[Less](http://lesscss.org/)、[Sass](https://sass-lang.com/)、[Stylus](http://stylus-lang.com/)。至于它们的选择，根据自己的喜好即可。Hexo 默认使用的是 Stylus，它的功能足够强大，完全够用，因此我选用了 Stylus。

### Hexo 相关知识

#### 创建hexo
**第一种方式**,去 [Hexo](https://hexo.io/zh-cn/) 官网，按照提示安装 hexo-cli 并生成你的 Hexo 工作目录，目录主要部分如下：
```
.
├── scaffolds
├── source
|   └── _posts
├── themes
├── .gitignore
├── _config.yml
└── package.json
```

**第二种方式**，克隆 [Hexo 官方的单元测试库](https://github.com/hexojs/hexo-theme-unit-test)，这样会得到同上的文件目录。然后执行指令` npm install `安装所有依赖。

对于一般的 Hexo 用户，基本都是使用第一种方式。不过对于 Hexo 主题开发者来说，如果你的主题将来要发布到 Hexo 的主题列表，建议直接在 Hexo 的主题单元测试项目中进行开发，也就是第二种方式。因为 Hexo 建议在主题发布前，对主题进行单元测试，确保每一项功能都能正常使用。Hexo 提供的单元测试库包括了所有的边缘情况，例如：文章标题过长时的显示效果、文章标题为空时的显示效果（是什么都不显示，还是显示一些默认的提示文字）、对 Front-Matter 的支持程度，等等。直接使用 Hexo 主题的单元测试项目作为你的开发目录，就可以在开发过程中注意到这些边缘情况，而不是开发完再去测试。

#### hexo 插件

搭建完 Hexo 开发环境后，需要安装相关插件来支持你所使用的渲染引擎。Hexo 默认安装的渲染引擎是 EJS 和 Stylus，并且 Hexo 内置了 Swig，因此，如果你选用了 EJS + Stylus 或 Swig + Stylus，那么可以忽略这段，如果你选择了其他的渲染引擎，需要自行选择安装：
```
# Templates
$ npm install --save hexo-renderer-ejs
$ npm install --save hexo-renderer-pug
$ npm install --save hexo-renderer-haml

# Styles
$ npm install --save hexo-renderer-less
$ npm install --save hexo-renderer-sass
$ npm install --save hexo-renderer-stylus
```

#### 生成主题结构目录

上一步只是搭建好了 Hexo 工作目录，接下来是创建主题的文件目录，你可以参考着已有的主题的文件目录手动创建，也可以使用 Yeoman 自动生成，使用 Yeoman 自动生成的步骤如下。

- 安装
```
$ npm install --global yo
$ npm install --global generator-hexo-theme
```
- 生成

进入 Hexo 的 themes 目录中，新建一个文件夹作为你的主题目录，然后进入该文件夹中，执行指令：
```
yo hexo-theme
```
按照提示，填写或选择相应的信息

```
生成的文件目录如下：

.
├── layout        # 布局文件夹
|   ├── includes
|   |   ├── layout.pug       # 页面总体布局
|   |   └── recent-posts.pug # 文章列表
|   ├── index.pug            # 首页
|   ├── archive.pug          # 归档页
|   ├── category.pug         # 分类页
|   ├── tag.pug              # 标签页
|   ├── post.pug             # 文章页
|   └── page.pug             # 除以上页面之外的页面
├── scripts       # 脚本文件夹
├── source        # 资源文件夹
|   ├── css
|   ├── js
|   └── favicon.ico
├── .editorconfig # 编辑器配置文件
├── _config.yml   # 主题配置文件
└── package.json
```

#### 通读文档

刚开始开发主题，不可能理解 Hexo 文档中提到的所有地方，但是有两个点必须首先掌握：[变量](https://hexo.io/zh-cn/docs/variables)和[辅助函数](https://hexo.io/zh-cn/docs/helpers)，这两点在开发时会经常用到，并且贯穿整个开发过程。


## 主题开发



