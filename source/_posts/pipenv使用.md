---
title: pipenv使用
date: 2019-12-13 14:00:00
categories: 
- python
tags:
- pipenv
- python
---


### 安装pipenv

`python2.7.x or python3.6.* `

```
pip install pipenv
```

### 启动pipenv

```
cd my_project
pipenv install
```

然后将目录更改为包含你的Python项目的文件夹，并启动Pipenv，这将在项目目录中创建两个新文件Pipfile和Pipfile.lock，如果项目不存在，则为项目创建一个新的虚拟环境。 如果你添加–two或–three标志到上面的最后一个命令，它分别使用Python 2或3来初始化你的项目。 否则将使用默认版本的Python。

### 管理python依赖关系

#### 安装Python包，请使用install关键字。

```
pipenv install beautifulsoup4
```

#### 卸载Python包，请使用uninstall关键字。

```
pipenv uninstall beautifulsoup4
```

#### 冻结软件包名称及其版本

```
pipenv lock
```

如果另一个用户克隆存储库，可以添加Pipfiles到你的Git存储库，这样他们只需要在他们的系统中安装Pipenv，Pipenv会自动找到Pipfiles，创建一个新的虚拟环境并安装必要的软件包。

```
pipenv install
```

### 管理开发环境

通常有一些Python包只在你的开发环境中需要，而不是在你的生产环境中，例如单元测试包。 Pipenv将使用–dev标志保持两个环境分开。

```
pipenv install --dev nose2
```

nose2，但也将其关联为只在开发环境中需要的软件包。 这很有用，因为现在，如果你要在你的生产环境中安装你的项目，

```
pipenv install
```

默认情况下不会安装nose2包。 但是，如果另一个开发人员将你的项目克隆到自己的开发环境中，他们可以使用–dev标志，

```
pipenv install –dev
```

并安装所有依赖项，包括开发包。

### 运行代码

为了激活与你的Python项目相关联的虚拟环境，你可以使用简单地shell命令，比如

```
pipenv run which python
```

将在你的虚拟环境中运行which python命令，并显示与你的虚拟环境相关联的python可执行文件所在的路径。 这是在虚拟环境中运行你自己的Python代码的一个简单方法，

```
pipenv run python my_project.py
```

如果你不想每次运行Python时都输入这么多，你可以在shell中设置一个别名，例如，

```
alias prp="pipenv run python"
```

### 用法

新建一个准备当环境的文件夹pipenvtest，并cd进入该文件夹：

| 命令                          | 说明                            | 例子 |
| ----------------------------- | ------------------------------- | ---- |
| `pipenv --three`              | 会使用当前系统的Python3创建环境 |      |
| `pipenv --python 3.6`         | 指定某一Python版本创建环境      |      |
| `pipenv shell`                | 激活虚拟环境                    |      |
| `pipenv --where`              | 显示目录信息                    |      |
| `pipenv --venv`               | 显示虚拟环境信息                |      |
| `pipenv --py`                 | 显示Python解释器信息            |      |
| `pipenv install requests`     | 安装相关模块并加入到Pipfile     |      |
| `pipenv install django==1.11` | 安装固定版本模块并加入到Pipfile |      |
| `pipenv graph`                | 查看目前安装的库及其依赖        |      |
| `pipenv check`                | 检查安全漏洞                    |      |
| `pipenv uninstall --all`      | 卸载全部包并从Pipfile中移除     |      |

### 设置国内源

可以设置国内源：

`Pipfile`文件中`[source]`下面`url`属性，比如修改成：

`url = "https://pypi.tuna.tsinghua.edu.cn/simple"`