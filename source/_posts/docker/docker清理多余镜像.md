---
title: 清理docker镜像
date: 2021-10-19 11:06
categories:
- docker
tags:
- images
---
	
	
摘要: desc
<!-- more -->


```
#!/bin/bash


# 需要保留的tag个数
retain_images_tag=6

#
#主函数入口
#
function main(){
_init_
gave_all_images
gave_file
delete_images_tag_file
delete_file_images
}

#
#init，将以前输出的txt文件删除
#
function _init_(){

rm -fr $PWD/docker-images
mkdir -p  $PWD/docker-images
rm -fr $PWD/delete_images_name.txt
rm -fr $PWD/name_images.txt
rm -fr array_name_images.txt
rm -fr array_detele_tag.txt
rm -fr all_delete_images.txt

}

#
#分割路径,我这里的镜像名称是  192.168.200.17/ranhcer/istio:2020344454-556 
#mkdir -p  192.168.200.17/ranhcer/istio:2020344454-556 就会自己形成路径层次
function gave_all_images(){

#echo "=============打印所有的镜像，可以刷选自己需要整理的镜像，不需要选择第一个echo=========="
#echo "$(docker images )" > $PWD/docker-images/images.txt
echo "$(docker images|grep 192.168.200.17/ |grep -v rancher|grep -v software|grep -v zhms )" > $PWD/docker-images/images.txt

#echo "=============镜像-名字=========="
sed -n '2,$p' $PWD/docker-images/images.txt | awk  '{print $1}' > $PWD/docker-images/name_images.txt
sort $PWD/docker-images/name_images.txt > $PWD/docker-images/array_name_images.txt

#echo "=============镜像-标签-名字=========="
sed -n '2,$p' $PWD/docker-images/images.txt | awk  '{print $1 $2}' > $PWD/docker-images/tag_name_images.txt

#echo "=============镜像-时间-标签-名字=========="
sed -n '2,$p' $PWD/docker-images/images.txt | awk  '{print $1 $2 $3}' > $PWD/docker-images/time_tag_name_images.txt
}

#
#获取镜像名称
#
function gave_file(){
test_flag=0
	for images_name in $(cat $PWD/docker-images/array_name_images.txt); do
		#statements	
		mkdir -p $PWD/docker-images/${images_name}/
		touch  $PWD/docker-images/${images_name}/tag.txt
		#echo "===========test_flag=$test_flag    images_name=$images_name=============="
        
        echo "==============start当前镜像名 $images_name=============="
        if [[ $test_flag -gt 0 ]]; then
        	#statements
	        if [[ ${images_name_array[$(($test_flag-1))]} != $images_name ]]; then
	        	#statements
	        	images_name_array[$test_flag]=$images_name
	        	echo "========== test_flag=$test_flag 存入镜像 images_name_array=${images_name_array[$test_flag]} ============"
	        	echo "$images_name" >> $PWD/delete_images_name.txt
	        	#echo "========== 输出数组为：${images_name_array[*]} ============"
	        	#echo "${images_name_array[*]}" >> $PWD/delete_images_name.txt
	        	test_flag=$[$test_flag+1]
	        	docker images |grep $images_name | awk '{print $2}' >  $PWD/docker-images/${images_name}/tag.txt
	        	sort  $PWD/docker-images/${images_name}/tag.txt >  $PWD/docker-images/${images_name}/array_tag.txt
	        fi        	 	
        else
        	images_name_array[$test_flag]=$images_name
        	echo "==========第一次存入镜像 images_name_array=${images_name_array[$test_flag]} ============"
        	echo "$images_name" >> $PWD/delete_images_name.txt
        	#statements
        	test_flag=$[$test_flag+1]
        	#echo "${images_name_array[*]}" >> $PWD/delete_images_name.txt
        	docker images |grep $images_name | awk '{print $2}' >  $PWD/docker-images/${images_name}/tag.txt
        	sort  $PWD/docker-images/${images_name}/tag.txt >  $PWD/docker-images/${images_name}/array_tag.txt
        fi
	done        	
}


#
#删除镜像
#
function delete_images_tag_file(){
	#echo "===镜像数组：${images_name_array[*]}"
	

	for array_images in $(cat $PWD/delete_images_name.txt); do
		#echo "====array_images=$array_images"
		num_all_row=$( sed -n '$=' $PWD/docker-images/${array_images}/array_tag.txt)
		#echo "========tag: 行数$num_all_row"
		array_images_flag=0

		echo -e "\n\n\n"
		for array_detele_tag in $(cat $PWD/docker-images/${array_images}/array_tag.txt); do
			echo "===需要删除的镜像：                 $array_images:$array_detele_tag"

			if [[ $num_all_row -le $retain_images_tag ]]; then
				echo "=========镜像$array_images:tag数目小于设定值，不需要删除======="
				break 
			fi

			if [[ $[$num_all_row - $array_images_flag ] -le $retain_images_tag ]]; then
				echo "=========镜像删除到预定值不需要继续删除，不在删除======="
				break 
			fi
			echo "$array_images:$array_detele_tag" >> $PWD/all_delete_images.txt
			array_images_flag=$[$array_images_flag+1]
		done
	done
}

function delete_file_images()
{
	detele_images_row=$( sed -n '$=' $PWD/all_delete_images.txt)
	if [[ $detele_images_row -le 0 ]]; then
		echo "=================没有需要删除的镜像==================="
		exit 0
	fi
	sed -i '/^ *$/d' $PWD/all_delete_images.txt
	for delete_tag_file in $(cat $PWD/all_delete_images.txt); do
		echo "====删除镜像   $delete_tag_file==== "
		echo " $(docker rmi $delete_tag_file)" 
	done
}
main
exit 0

```