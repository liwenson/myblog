---
title: windows10系统文件修复
date: 2021-06-22 09:45
categories:
- windows
tags:
- win10
---
	
	
摘要: win10 系统文件修复
<!-- more -->

## DISM 和 SFC 检查工具修复系统

Win + S 键搜索栏输入 CMD 找到 “命令提示符”，右键以管理员身份打开，小心复制及贴上执行以下多条命令(需要联网操作，一次一行)
```
DISM.exe /Online /Cleanup-Image /ScanHealth

DISM.exe /Online /Cleanup-Image /CheckHealth

DISM.exe /Online /Cleanup-image /Restorehealth
```

无论上面三条命令是否有显示错误或成功，最后再键入以下命令：
```
sfc /scannow
```

完成后重启