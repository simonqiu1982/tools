#!/bin/bash
echo "=================================================================="
set +x
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

update_version(){
	LINK_ROOT_PATH="/data/senselink-edge-all"
	arr=(web link toolkit feature attendance ntp ota emqx redis mysql webrtc)
	declare -A dic
	
	result=true
	while [ "$result" = true ]
	do
		echo ""
		echo "**********************EDGE MODEL*************************"
		echo ""
		for i in "${!arr[@]}"; 
		do 
			printf "%s - %s\n" "$i" "${arr[$i]}"
			dic+=([$i]="${arr[$i]}")
		done
		echo ""
		echo "Please choose to update version:"
		read edge_model
		
		if [ ! ${dic["${edge_model}"]} ]; then
			echo_red "No such model no: $edge_model"
		else
			result=false
		fi
	done

	image_name=${dic["${edge_model}"]}
	folder_name=${dic["${edge_model}"]}
	[ ${image_name} = "toolkit" ] && folder_name="tk"
	work_path="${LINK_ROOT_PATH}/link-edge/$folder_name"
	[ ! -d  "$work_path" ] && work_path="${LINK_ROOT_PATH}/middleware/$folder_name"
	[ ! -d  "$work_path" ] && echo_red "No such directory: $work_path" && exit_script
	
	echo ""
	echo "**********************MODEL VERSION*************************"
	echo ""
	echo "Please enter the ${image_name} version:"
	read model_version
	
	cd ${work_path}/..
	cfg_modify version "${image_name}" "$model_version"
	[ ${image_name} = "webrtc" ] && image_name="mms"
	docker rm -f ${image_name}
	cd ${work_path}
	sh run.sh
	
}

init_edge(){

	DATA_PATH=${link_data_path}/senselink
	result=true
	while [ "$result" = true ]
	do
	
		echo ""
		echo "**********************EDGE VERSION*************************"
		echo ""
		echo "1 - 0.1.0"
		echo "2 - 0.2.1"
		echo "3 - 0.4.0"
		echo "4 - 0.5.0"
		echo "5 - 0.2.1 - POC"
		echo "6 - 1.0.0 - stable"
		echo ""
		echo "Please choose to install:"
		read install_edge_version
		
		result=false
		case $install_edge_version in
			1)
				edge_010
				;;
			2)
				edge_version='0.2.1'
				edge
				;;
			3)
				edge_version='0.4.0'
				edge
				;;
			4)
				edge_version='0.5.0'
				edge
				;;
			5)
				edge_poc_021
				;;
			6)
				edge_version='1.0.0'
				edge
				;;
			*)
				echo_red "No version is found: $install_edge_version"
				result=true
		esac
	done
}

edge_poc_021(){

	LINK_ROOT_PATH=/data/senselink-edge-all
	DATA_RUNDIR=/data/rundir
	HOME_LINK=/home/senselink-edge-all
	
	#clean files
	echo ""
	echo "Stopping link..."
	[ -d $LINK_ROOT_PATH ] && cd $LINK_ROOT_PATH && sh stop.sh
	[ `docker ps -aq | wc -l` -ne 0 ] && docker rm -f $(docker ps -aq)
	[ -L $HOME_LINK ] &&  unlink $HOME_LINK
	[ -e  "$LINK_ROOT_PATH" ] && rm -rf "$LINK_ROOT_PATH"
	[ -e  "$DATA_RUNDIR" ] && rm -rf "$DATA_RUNDIR"
	
	cd /data
	curl -O --fail http://pkg.bi.sensetime.com/senselink-edge-v0.2.1.0-20210715-all-1.tar.gz
	[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit 2
	tar -zxvf senselink-edge-v0.2.1.0-20210715-all-1.tar.gz
	
	cd $LINK_ROOT_PATH
	
	#删除安装锁
	[ -e /tmp/link_* ] && rm -rf /tmp/link_*
	sh install.sh
	
	source $LINK_ROOT_PATH/config
	echo "Data directory is $senselink_config_path"
}

edge(){

	LINK_ROOT_PATH=/data/senselink-edge-all
	HOME_RUNDIR=/home/rundir
	HOME_LINK=/home/senselink-edge-all
	
	#clean files
	echo ""
	echo "Stopping link..."
	[ -d $LINK_ROOT_PATH ] && cd $LINK_ROOT_PATH && sh stop.sh
	[ `docker ps -aq | wc -l` -ne 0 ] && docker rm -f $(docker ps -aq)
	[ -L $HOME_LINK ] &&  unlink $HOME_LINK
	[ -e  "$LINK_ROOT_PATH" ] && rm -rf "$LINK_ROOT_PATH"
	[ -e  "$HOME_RUNDIR" ] && rm -rf "$HOME_RUNDIR"
	
	cd /data
	curl -O --fail http://pkg.bi.sensetime.com/senselink-edge-all-v$edge_version.tar.gz
	[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit 2
	tar -zxvf senselink-edge-all-v$edge_version.tar.gz
	
	cd $LINK_ROOT_PATH
	docker login -u liuhongxu  -p a123456@ registry.sensetime.com
	
	[ ! -e $DATA_PATH ] && mkdir -p $DATA_PATH
	#change config path
	cfg_modify config "senselink_config_path" "$DATA_PATH"
	
	#删除安装锁
	[ -e /tmp/link_* ] && rm -rf /tmp/link_*
	sh install.sh
	
	source $LINK_ROOT_PATH/config
	echo "Data directory is $senselink_config_path"
}
	
edge_010(){
	
	INSTALL_PACKAGES_PATH=/data/packages/edge
	VIPERLITE_INSTALL_PATH=/data/rundir
	VIPERLITE_ROOT_PATH=$VIPERLITE_INSTALL_PATH/sensetime/viper-lite
	LINK_ROOT_PATH=/data/senselink-edge-deploy
	HOME_RUNDIR=/home/rundir

	if [ -f  $LINK_ROOT_PATH/config ]; then
		source $LINK_ROOT_PATH/config
	fi

	#停止docker应用
	[ `docker ps -aq | wc -l` -ne 0 ] && docker rm -f $(docker ps -aq)
	[ -L $HOME_RUNDIR ] &&  unlink $HOME_RUNDIR
	#删除旧的数据
	echo "$VIPERLITE_INSTALL_PATH"
	echo "$LINK_ROOT_PATH"
	echo "$senselink_config_path"
	echo "$HOME_RUNDIR"
	echo ""
	echo "Do you want to delete these folders? [y/n]:"
	read is_remove
	[ -z  "$is_remove" ] && echo_red "Wrong input" && exit 2
	[ "y"="$is_remove" ] && rm -rf $VIPERLITE_INSTALL_PATH $LINK_ROOT_PATH $senselink_config_path $HOME_RUNDIR


	#开始安装
	mkdir -p $INSTALL_PACKAGES_PATH
	mkdir -p $VIPERLITE_INSTALL_PATH/sensetime
	ln -s $VIPERLITE_INSTALL_PATH /home/

	(cd $INSTALL_PACKAGES_PATH && curl -O --fail http://10.4.10.135/download/viper-lite-v2.1.2.tar)
	[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit 2
	tar -xvf $INSTALL_PACKAGES_PATH/viper-lite-v2.1.2.tar -C $VIPERLITE_INSTALL_PATH/sensetime > /dev/null 2>&1
	[ ! -d  "$VIPERLITE_INSTALL_PATH" ] && echo "No Data is downloaded" && exit 2

	(cd $INSTALL_PACKAGES_PATH && curl -O --fail http://10.4.10.135/download/senselink-edge-deploy-v0.1.0.tar)
	[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit 2
	tar -xvf $INSTALL_PACKAGES_PATH/senselink-edge-deploy-v0.1.0.tar -C /data > /dev/null 2>&1
	[ ! -d  "$LINK_ROOT_PATH" ] && echo_red "No Data is downloaded" && exit 2
	[ ! -f  "$LINK_ROOT_PATH/config" ] && echo_red "No config file found" && exit 2
	

	docker login -u liuhongxu  -p a123456@ registry.sensetime.com
	
	cd $LINK_ROOT_PATH
	[ ! -e $DATA_PATH ] && mkdir -p $DATA_PATH
	#change config path
	cfg_modify config "senselink_config_path" "$DATA_PATH"
	./run_all.sh
	
	cd $VIPERLITE_ROOT_PATH
	./install.sh
	(cd $VIPERLITE_ROOT_PATH/infra/config/licenseca/ && curl -O --fail http://10.152.244.7/download/client.lic)
	[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit 2
	
	#结束安装
	#Edge0.1.0特殊操作
	cd $LINK_ROOT_PATH
	update_db_message=`./update_db.sh 2>&1`
	while [[ "$update_db_message" != *"ERROR 1060"* ]]
	do
		sleep 1s
		echo [[ "$update_db_message" ]]
		update_db_message=`./update_db.sh 2>&1`
	done
	
	source $LINK_ROOT_PATH/config
	echo "Data directory is $senselink_config_path"
}

rom(){
	
	INSTALL_ROM_PACKAGES_PATH=${link_data_path}/packages/rom
	
	rm -rf $INSTALL_ROM_PACKAGES_PATH
	mkdir -p $INSTALL_ROM_PACKAGES_PATH
	
	echo ""
	echo "**********************ROM VERSION*************************"
	cat  /lib/modules/s100box/build.info
	echo "**********************************************************"
	result=true
	while [ "$result" = true ]
	do
		echo ""
		echo "1 - 0.5.1"
		echo "2 - 0.5.2"
		echo "3 - 0.5.3 - stable"
		echo "0 - enter my link"
		echo "9 - Must install after rom updated!!!"
		echo ""
		echo "Please choose rom version to install:"
		read userinput
		
		result=false
		case $userinput in
			0)
				echo "Please enter the full path(http:// or /data/xxx.tar.gz):"
				read input_link
				if [[ $input_link == http://* ]]; then
					(cd $INSTALL_ROM_PACKAGES_PATH && curl -O --fail $input_link)
					[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit_script
				elif [ ! -f $input_link ] ; then
					echo_red "Package NOT FOUND:$input_link" && exit_script
				else
					cp $input_link $INSTALL_ROM_PACKAGES_PATH
				fi
				echo "download done"
				;;
			1)
				(cd $INSTALL_ROM_PACKAGES_PATH && curl -O --fail http://10.9.244.234/SensePallasRom/release/0.5.1/build_54/s100box_v0.5.1_54_ChangJiang.tar.gz)
				[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit_script
				echo "download done"
				;;
			2)
				(cd $INSTALL_ROM_PACKAGES_PATH && curl -O --fail http://10.9.244.234/SensePallasRom/release/0.5.2/build_69/s100box_v0.5.2_69_ChangJiang.tar.gz)
				[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit_script
				echo "download done"
				;;
			3)
				(cd $INSTALL_ROM_PACKAGES_PATH && curl -O --fail http://10.9.244.234/SensePallasRom/release/0.5.3/build_77/s100box_v0.5.3_77_ChangJiang.tar.gz)
				[ $? -ne 0 ] && echo_red "Package NOT FOUND" && exit_script
				echo "download done"
				;;
			9)
				echo "开始恢复出厂设置"
				fw_setenv factory_reset 1
				reboot
				exit_script
				;;

			*)
				echo_red "No module no is found: $userinput"
				result=true
		esac
	done
		
	cd $INSTALL_ROM_PACKAGES_PATH
	echo "unzip file ..."
	tar -xvf *  > /dev/null 2>&1
	echo "unzip done"
	cd $( ls -F |grep "/$")
	box_update.sh --otaname $( ls *.tar.gz )
}

cfg_modify(){
    file_name=$1
    key=$2
    new_value=$3
	ln=`cat -n $file_name|grep $key|awk '{print $1}'`
	[ -z  "$ln" ] && echo_red "The key=${key} is not found in $1" && exit_script
	
	key_value=$(cat $file_name | sed -n $ln"p")
	key=$(echo $key_value | awk -F '=' '{print $1}')
	new_key_value=$key"="$new_value
	sed -i ""$ln"s|.*|"$new_key_value"|g" $file_name
	sed -n ""$ln"p" $file_name
}

get_link_data_path(){
    #简单判断Size大于50G的就是ssd
	default_size=$(( 50 * 1024 * 1024 ))
	default_avail_size=$(( 5 * 1024 * 1024 ))
	largest_size=`df -k | awk '{ print $2 " " $6 }'|sort -nr | sed -n "1,1p"|awk '{ print $1 }'`
	largest_size_path=`df -k | awk '{ print $2 " " $6 }'|sort -nr | sed -n "1,1p"|awk '{ print $2 }'`
	link_data_path='/data'
	if [ $largest_size -gt $default_size ]; then
		link_data_path=$largest_size_path
	fi
	#判断可用空间是否大于5G
	avail_size=`df -k |grep $link_data_path |awk '{ print $4}'`
	if [ $avail_size -lt $default_avail_size ]; then
		((i=$avail_size/1024/1024))
		echo_red "Error! The avail space should larger than 5G, current: ${i}G $link_data_path" && exit_script
	fi
}

function echo_red() {
        echo -e "\E[31m${1}\E[0m"
}

function echo_green() {
        echo -e "\E[32m${1}\E[0m"
}

function echo_yellow() {
        echo -e "\E[33m${1}\E[0m"
}

function echo_blue() {
        echo -e "\E[34m${1}\E[0m"
}

function echo_pink() {
        echo -e "\E[35m${1}\E[0m"
}

#main function start from here
export TOP_PID=$$
trap 'exit 2' TERM

exit_script(){
    kill -s TERM $TOP_PID
}

link_data_path=""
get_link_data_path

result=true
while [ "$result" = true ]
do
	echo "0 - rom"
	echo "1 - edge"
	echo "2 - update version"
	echo ""
	echo "Please choose to install:"
	read install_module
	
	result=false
	case $install_module in
		0)
			rom
			;;
		1)
			init_edge
			;;
		2)
			update_version
			;;
		*)
			echo_red "No module no is found: $install_module"
			result=true
	esac
	
done

echo "=================================================================="
