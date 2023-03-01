#!/bin/bash -xe

Progressbar() {
  i=0
  count=0
  bar=""
  flen=$(ls -l "$1" | grep "^-" -c)
  blen=40
  if [ "${flen}" -eq 0 ]; then
    printf "dir %s is empty\n" "$1"
    return
  else
    printf "dir %s have %d files\n" "$1" "$flen"
    add=$(echo "scale=6;100/$flen" | bc)
    badd=$(echo "$flen/$blen" | bc)
    ((badd++))
    #    echo "$flen", "$badd", "$add"
    list=$(ls "$1")
    for file in $list; do
      i=$(echo "$i+$add" | bc)
      ((count++))
      if [ $(echo "$count%$badd" | bc) -eq 0 ]; then
        bar+='='
      fi
      printf "\e[32;1m[%-*s][%6.2f%% %4d/%d] %21s\r" "$blen" "$bar" "$i" "$count" "$flen" "$file"
      rm "$1" "$file"
    done
    bar+='='
    i=100
    printf "\e[32;1m[%-*s][%6.2f%% %4d/%d] %21s\n" "$blen" "$bar" "$i" "$count" "$flen" "$file"
    printf "\e[0m"
  fi
}

path=detection/
Progressbar $path
