#!/usr/bin/env bash

currentTime=$(date "+%Y-%m-%d %H:%M:%S")

currentTimeStamp=$(date -d "$currentTime" +%s)

curl "https://oapi.dingtalk.com/robot/send?access_token=d626a72a47eca0fc36254d4c008769486187a73afbb1b044d081547e097585c0&timestamp=${currentTimeStamp}
" \
  -H 'Content-Type: application/json' \
  -d '{"msgtype": "text","text": {"content":"我就是我, 是不一样的烟火"}}'
