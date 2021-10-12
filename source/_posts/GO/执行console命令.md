---
title: Golang 执行 Console 命令
date: 2021-09-30 17:09
categories:
- go
tags:
- go
---
	
	
摘要: desc
<!-- more -->




但是能做交互, 并且可以持续获取控制台返回结果的,还是比较少的,

```
import (
    "bufio"
    "fmt"
    "io"
    "os/exec"
)

func main() {
    execCmd("ps", []string{"-a"})
}
func execCmd(shell string, raw []string) (int, error) {
    cmd := exec.Command(shell, raw...)
    stdout, err := cmd.StdoutPipe()
    if err != nil {
        fmt.Println(err)
        return 0, nil
    }
    stderr, err := cmd.StderrPipe()
    if err != nil {
        fmt.Println(err)
        return 0, nil
    }
    if err := cmd.Start(); err != nil {
        fmt.Println(err)
        return 0, nil
    }
    s := bufio.NewScanner(io.MultiReader(stdout, stderr))
    for s.Scan() {
        text := s.Text()
        fmt.Println(text)
    }
    if err := cmd.Wait(); err != nil {
        fmt.Println(err)
    }
    return 0, nil
}
```


## golang执行系统命令,并不断获取输出
```
package main

import (
	"bufio"
	"fmt"
	"os/exec"

	"golang.org/x/text/encoding/simplifiedchinese"   // 解决乱码问题
)

func getOutputDirectly(name string, args ...string) (output []byte) {
	cmd := exec.Command(name, args...)
	output, err := cmd.Output() // 等到命令执行完, 一次性获取输出
	if err != nil {
		panic(err)
	}
	output, err = simplifiedchinese.GB18030.NewDecoder().Bytes(output)
	if err != nil {
		panic(err)
	}
	return
}

func getOutputContinually(name string, args ...string) <-chan struct{} {
	cmd := exec.Command(name, args...)
	closed := make(chan struct{})
	defer close(closed)

	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		panic(err)
	}
	defer stdoutPipe.Close()

	go func() {
		scanner := bufio.NewScanner(stdoutPipe)
		for scanner.Scan() { // 命令在执行的过程中, 实时地获取其输出
			data, err := simplifiedchinese.GB18030.NewDecoder().Bytes(scanner.Bytes()) // 防止乱码
			if err != nil {
				fmt.Println("transfer error with bytes:", scanner.Bytes())
				continue
			}

			fmt.Printf("%s\n", string(data))
		}
	}()

	if err := cmd.Run(); err != nil {
		panic(err)
	}
	return closed
}

func main() {
	// 效果: 等一会儿, 打印出所有输出
	output1 := getOutputDirectly("tree")
	fmt.Printf("%s\n", output1)

	// 不断输出, 直到结束
	<-getOutputContinually("tree")
}

```