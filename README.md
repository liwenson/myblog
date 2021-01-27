## 博客源码

操作步骤

1、切换到 source 分支
git checkout source
2、编辑文档
3、合并master 到 source
git checkout source && git merge master
4、提交到 origin source 远程分支
git push origin source
5、切换到master 分支
git checkout master
6、更新远程分支source 到master
git pull origin source 
7、更新文档
8、发布文档
hexo g && hexo d
