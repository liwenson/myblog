---
title: git 常用命令
date: 2021-10-19 11:19
categories:
- git
tags:
- git
---
	
	
摘要: git 常用命令
<!-- more -->


## 配置操作
### 全局配置
```
git config --global user.name '你的名字'
git config --global user.email '你的邮箱'
```

### 当前仓库配置
```
git config --local user.name '你的名字'
git config --local user.email '你的邮箱'
```

### 查看global 配置
```
git config --global --list
```

### 查看当前仓库配置
```
git config --local --list
```

### 删除global 配置
```
git config --unset --global '要删除的配置项'
```

### 删除当前仓库配置
```
git config --unset --local '要删除的配置项'
```

## 本地操作

### 查看变更记录
```
git status
```

### 将当前目录及其子目录所有变更都加入到暂存区
```
git add .
```

### 将仓库内所有变更都加入到暂存区
```
git add -A
```

### 将指定的文件添加到暂存区
```
git add 文件一 文件二 文件三
```

### 比较工作区和暂存区的差异
```
git diff 
```

### 比较某个文件 工作区和暂存区的差异
```
git diff 文件
```

### 比较暂存区和 HEAD 的所有差异
```
git diff --cached
```

### 比较某个文件 暂存区和 HEAD 的差异
```
git diff --cached 文件
```

### 创建 commit 
```
git commit -m "描述"
```

### 将工作区指定文件恢复成和暂存区一致
```
git checkout 文件1 文件2 文件3
```

### 将暂存区指定文件恢复成和 HEAD 一致
```
git reset 文件1 文件2
```

### 将暂存区和工作区所有文件恢复成和 HEAD 一致
```
git reset --hard 
```

### 用 difftool 比较任意两个 commit 的差异
```
git difftool commitID1 commitID2
```

### 查看哪些文件没被 Git 管控
```
git ls-files --others
```

### 将未处理完的变更先保存到 stash 中
```
gti stash 
``` 

### 临时任务处理完后继续之前的工作
```
pop      不保留stash
apply    保留stash


git stash pop   #不保留
git stash  apply  # 保留
```

### 查看所有 stash
```
git stash list
```

### 取回某一次stash 的变更
```
git stash pop stash@{数字N}
```

### 优雅修改最后一次 commit 
```
git add . 
git commit --amend
```


## 分支操作

### 查看当前工作分支及本地分支
```
git branch -v
```

### 查看本地和远端分支
```
git branch -av
```

### 查看远端分支
```
git branch -rv
```

### 切换到指定分支
```
git checkout 指定分支
```

### 基于当前分支创建新分支
```
git branch 新分支名称
```

### 指定分支创建新分支
```
git branch 新分支  指定分支
```

### 基于某个 commit 创建新分支
```
git branch 新分支 某个 commit ID
```

### 创建并切换到该分支
```
git checkout -b 新分支
```

### 安全删除本地某分支
```
git branch -d 要删除的分支
```

### 强行删除本地某分支
```
git branch -D  要删除的分支
```

### 删除已合并到 master 分支的所有本地分支
```
git branch --merged master | grep -v '^\*\| master' | xargs -n git branch -d
```

### 删除远端 origin 已不存在的所有本地分支
```
git remote prune origin
```

### 将 A 分支合入到当前分支中且为merge 创建 commit
```
git merge A分支
```

### 将 A分支 合入到 B分支 中且为 merge创建 commit 
```
git merge A分支 B分支
```

### 将当前分支基于 B分支 做rebase ，以便将 B分支 合入到当前分支
```
git rebase B分支
```

### 将 A分支 基于 B分支 做 rebase ，以便将 B分支 合入到 A分支
```
git rebase B分支 A分支
```

## 变更历史

### 当前分支各个 commit 用一行显示
```
git log --oneline
```

### 显示就近的 n 个 commit
```
git log -n 
```

### 用图示显示所有分支的历史
```
git log --oneline --graph --all
```

### 查看涉及某文件变更的所有 commit
```
git log  文件
```

### 某文件各行最后修改对应的 commit 已经作者
```
git blame 文件
```

## 标签

### 查看已有的标签
```
git tag
```

### 新建标签
```
git tag v1.0
```

### 新建带备注标签
```
git tag -a v1.0 -m "前端发布"
```

### 给指定的 commit 打标签
```
git tag v1.0 commitID
```

### 推送一个本地标签
```
git push origin v1.0
```

### 推送全部未推送过的本地标签
```
git push origin --tags
```

### 删除一个本地标签
```
git tag -d v1.0
```

### 删除一个远端标签
```
git push origin :refs/tags/v1.0
```

## 远端交互

### 查看所有远端仓库
```
git remote -v
```


### 添加远端仓库
```
git remote add '别名' '仓库URL'
```

### 删除远端仓库
```
git remote remove remote的别名
```

### 重命名远端仓库
```
git remote rename 旧名称 新名称
```

### 将远端所有分支和标签的变更都拉到本地
```
git fatch remote
```

### 把远端分支的变更拉到本地，且 merge 到本地分支
```
git pull origin 分支名
```

### 将本地分支 push 到远端
```
git push origin 分支名
```


### 删除远端分支
```
git push remote --delete 远端分支名称

git push remote :远端分支名
```