#!/bin/bash
echo "=================================================================="
set +x
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

edge_021(){
	LINK_ROOT_PATH=/data/senselink-edge-all
	HOME_RUNDIR=/home/rundir
	
	#clean files
	(docker rm -f $(docker ps -aq))
	[ -e  "$LINK_ROOT_PATH" ] && rm -rf "$LINK_ROOT_PATH"
	[ -e  "$HOME_RUNDIR" ] && rm -rf "$HOME_RUNDIR"
	
	cd /data
	curl -O --fail http://pkg.bi.sensetime.com/senselink-edge-all-v0.2.1-2.4.2.5-0621-pu-ic-20210621.zip
	[ $? -ne 0 ] && echo "Package NOT FOUND" && exit 2
	unzip senselink-edge-all-v0.2.1-2.4.2.5-0621-pu-ic-20210621.zip
	
	cd $LINK_ROOT_PATH
	docker login -u liuhongxu  -p a123456@ registry.sensetime.com
	
	[ ! -e $DATA_PATH ] && mkdir -p $DATA_PATH
	#change config path
	cfg_modify config "senselink_config_path" "$DATA_PATH"
	
	sh install-test.sh
	
	source $LINK_ROOT_PATH/config
	echo "Data directory is $senselink_config_path"
}

edge_040(){
	LINK_ROOT_PATH=/data/senselink-edge-all
	HOME_RUNDIR=/home/rundir
	
	#clean files
	(docker rm -f $(docker ps -aq))
	[ -e  "$LINK_ROOT_PATH" ] && rm -rf "$LINK_ROOT_PATH"
	[ -e  "$HOME_RUNDIR" ] && rm -rf "$HOME_RUNDIR"
	
	cd /data
	curl -O --fail http://pkg.bi.sensetime.com/senselink-edge-all-v0.4.0-2.4.2.5-0622-algo-20210622.zip
	[ $? -ne 0 ] && echo "Package NOT FOUND" && exit 2
	unzip senselink-edge-all-v0.4.0-2.4.2.5-0622-algo-20210622.zip
	
	cd $LINK_ROOT_PATH
	docker login -u liuhongxu  -p a123456@ registry.sensetime.com
	
	[ ! -e $DATA_PATH ] && mkdir -p $DATA_PATH
	#change config path
	cfg_modify config "senselink_config_path" "$DATA_PATH"
	
	sh install-test.sh
	
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
	(docker rm -f $(docker ps -aq))
	[ -L $HOME_RUNDIR ] &&  unlink $HOME_RUNDIR
	#删除旧的数据
	read -p $'Do you want to delete below folders? [y/n] \x0a'$VIPERLITE_INSTALL_PATH$'\x0a'$LINK_ROOT_PATH$'\x0a'$senselink_config_path$'\x0a'$HOME_RUNDIR$'\x0a' is_remove

	[ -z  "$is_remove" ] && echo "Wrong input" && exit 2
	[ "y"="$is_remove" ] && rm -rf $VIPERLITE_INSTALL_PATH $LINK_ROOT_PATH $senselink_config_path $HOME_RUNDIR


	#开始安装
	mkdir -p $INSTALL_PACKAGES_PATH
	mkdir -p $VIPERLITE_INSTALL_PATH/sensetime
	ln -s $VIPERLITE_INSTALL_PATH /home/

	(cd $INSTALL_PACKAGES_PATH && curl -O --fail http://10.4.10.135/download/viper-lite-v2.1.2.tar)
	[ $? -ne 0 ] && echo "Package NOT FOUND" && exit 2
	tar -xvf $INSTALL_PACKAGES_PATH/viper-lite-v2.1.2.tar -C $VIPERLITE_INSTALL_PATH/sensetime > /dev/null 2>&1
	[ ! -d  "$VIPERLITE_INSTALL_PATH" ] && echo "No Data is downloaded" && exit 2

	(cd $INSTALL_PACKAGES_PATH && curl -O --fail http://10.4.10.135/download/senselink-edge-deploy-v0.1.0.tar)
	[ $? -ne 0 ] && echo "Package NOT FOUND" && exit 2
	tar -xvf $INSTALL_PACKAGES_PATH/senselink-edge-deploy-v0.1.0.tar -C /data > /dev/null 2>&1
	[ ! -d  "$LINK_ROOT_PATH" ] && echo "No Data is downloaded" && exit 2
	[ ! -f  "$LINK_ROOT_PATH/config" ] && echo "No config file found" && exit 2
	

	docker login -u liuhongxu  -p a123456@ registry.sensetime.com
	
	cd $LINK_ROOT_PATH
	[ ! -e $DATA_PATH ] && mkdir -p $DATA_PATH
	#change config path
	cfg_modify config "senselink_config_path" "$DATA_PATH"
	./run_all.sh
	
	cd $VIPERLITE_ROOT_PATH
	./install.sh
	(cd $VIPERLITE_ROOT_PATH/infra/config/licenseca/ && curl -O --fail http://10.152.244.7/download/client.lic)
	[ $? -ne 0 ] && echo "Package NOT FOUND" && exit 2
	
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
	INSTALL_ROM_PACKAGES_PATH=/data/packages/rom

	rm -rf $INSTALL_ROM_PACKAGES_PATH
	mkdir -p $INSTALL_ROM_PACKAGES_PATH

	cat  /lib/modules/s100box/build.info

	echo "Please choose rom version to install:"
	echo "0 - enter my link"
	echo "1 - 0.5.0"
	echo "999 - rom更新后执行"
	 
	read userinput

	case $userinput in
		0)
			echo "Please enter the full link:"
			read input_link
			(cd $INSTALL_ROM_PACKAGES_PATH && curl -O --fail $input_link)
			[ $? -ne 0 ] && echo "Package NOT FOUND" && exit 2
			echo "download done"
			;;
		1)
			(cd $INSTALL_ROM_PACKAGES_PATH && curl -O --fail http://10.9.244.234/SensePallasRom/release/0.5.0/build_49/s100box_v0.5.0_49_ChangJiang.tar.gz)
			[ $? -ne 0 ] && echo "Package NOT FOUND" && exit 2
			echo "download done"
			;;
		999)
			echo "开始恢复出厂设置"
			fw_setenv factory_reset 1
			reboot
			;;

		*)
			echo "No module is found"
			exit 2
	esac
		
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
	[ -z  "$ln" ] && echo $key" not found" && exit 2
	
	key_value=$(cat $file_name | sed -n $ln"p")
	key=$(echo $key_value | awk -F '=' '{print $1}')
	new_key_value=$key"="$new_value
	sed -i ""$ln"s|.*|"$new_key_value"|g" $file_name
	sed -n ""$ln"p" $file_name
}

ssd_path(){
    #简单判断大于50G的就是ssd
	default_size=$(( 50 * 1024 * 1024 ))
	largest_size=`df -k | awk '{ print $2 " " $6 }'|sort -nr | sed -n "1,1p"|awk '{ print $1 }'`
	largest_size_path=`df -k | awk '{ print $2 " " $6 }'|sort -nr | sed -n "1,1p"|awk '{ print $2 }'`
	default_data_path='/data'
	if [ $largest_size -gt $default_size ]; then
		default_data_path=$largest_size_path
	fi
	echo $default_data_path/senselink
}

#main function start from here
echo "Please choose to install:"
echo "0 - rom"
echo "1 - edge-0.1.0"
echo "2 - edge-0.2.1"
echo "3 - edge-0.4.0"

read install_module

DATA_PATH=`ssd_path`

case $install_module in
	0)
        rom
        ;;
    1)
        edge_010
        ;;
	2)
		edge_021
		;;
	3)
		edge_040
		;;
    *)
        echo "No module is found"
		exit 2
esac

echo "=================================================================="
