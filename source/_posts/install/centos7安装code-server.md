#---
title: centos7 安装code-server
date: 2022-03-16 11:39
categories:
- centos7
tags:
- code-server
- vscode
---
  
  
摘要: desc
<!-- more -->

## 文档

[文档](https://coder.com/docs/code-server/latest/guide)

[Github](https://github.com/coder/code-server)

[安装包下载](https://github.com/coder/code-server/releases)

## 安装

ubuntu

```bash
curl -fOL https://github.com/cdr/code-server/releases/download/v$VERSION/code-server_$VERSION_amd64.deb
sudo dpkg -i code-server_$VERSION_amd64.deb
sudo systemctl enable --now code-server@$USER
sudo systemctl start code-server@$USER

# Now visit http://127.0.0.1:8080. Your password is in ~/.config/code-server/config.yaml
```

centos

```bash
curl -fOL https://github.com/cdr/code-server/releases/download/v$VERSION/code-server_$VERSION_amd64.rpm
yum install code-server_$VERSION_amd64.rpm
systemctl enable --now code-server@$USER
system start code-server@$USER

# Now visit http://127.0.0.1:8080. Your password is in ~/.config/code-server/config.yaml
```

## 配置
```
vim ~/.config/code-server/config.yaml

bind-addr: 127.0.0.1:8080  改成 0.0.0.0:9999
auth: password
password: e8aeffc481faf3137466952f
cert: false
```

## 启动
```
systemctl restart code-server@$USER
```

## code-server 环境配置

安装插件
```
/usr/bin/code-server --install-extension ms-python.python
/usr/bin/code-server --install-extension esbenp.prettier-vscode
/usr/bin/code-server --install-extension equinusocio.vsc-material-theme
/usr/bin/code-server --install-extension codezombiech.gitignore
/usr/bin/code-server --install-extension piotrpalarz.vscode-gitignore-generator
/usr/bin/code-server --install-extension aeschli.vscode-css-formatter
/usr/bin/code-server --install-extension donjayamanne.githistory
/usr/bin/code-server --install-extension ecmel.vscode-html-css
/usr/bin/code-server --install-extension pkief.material-icon-theme
/usr/bin/code-server --install-extension equinusocio.vsc-material-theme-icons
/usr/bin/code-server --install-extension eg2.vscode-npm-script
/usr/bin/code-server --install-extension ms-ceintl.vscode-language-pack-zh-hans
/usr/bin/code-server --install-extension ~/.local/extensions/tkrkt.linenote-1.2.1.vsix
/usr/bin/code-server --install-extension dbaeumer.vscode-eslint
```