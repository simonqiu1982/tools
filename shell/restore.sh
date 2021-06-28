#!/bin/bash
echo "=================================================================="
set +x
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

FTP_HOST="10.152.244.7"
FTP_FOLDER_NAME=""
FTP_URI="download/backup"


edge(){
	LINK_ROOT_PATH="/data/senselink-edge-all"
	[ ! -d  "$LINK_ROOT_PATH" ] && echo "No link platform installed: $LINK_ROOT_PATH" && exit 2
	[ ! -f $LINK_ROOT_PATH/config ] && echo "No config file exists: $LINK_ROOT_PATH/config" && exit 2
	source $LINK_ROOT_PATH/config
	[ ! -d  "$senselink_config_path" ] && echo "No config directory found: $senselink_config_path" && exit 2
	
	INSTALL_PACKAGES_PATH="$senselink_config_path/packages/restore"
	
	
	package_afd="afd.tar.gz"
	package_base="senselink6base.tar.gz"
	sql_viper_lite_db="viper_lite_db.sql"
	sql_t_company="t_company.sql"
	sql_t_group="t_group.sql"
	sql_t_group_user="t_group_user.sql"
	sql_t_user="t_user.sql"
	sql_t_department="t_department.sql"
	sql_t_multi_feature="t_multi_feature.sql"
	
	sql_get_user_count="select count(1) as total FROM bi_slink_base.t_user;"
	sql_get_static_features_count="select count(1) as total FROM viper_lite.static_features;"
	
	FTP_LINK="http://$FTP_HOST/$FTP_URI/$FTP_FOLDER_NAME"
	
	HOSTNAME=$mysql_ip
	PORT=$mysql_port
	USERNAME=$mysql_user
	PASSWORD=$mysql_password
	echo $HOSTNAME:$PORT@$USERNAME:$PASSWORD
	export MYSQL_PWD=$PASSWORD
	
	[ -d  "$INSTALL_PACKAGES_PATH" ] && rm -rf "$INSTALL_PACKAGES_PATH"
	mkdir -p $INSTALL_PACKAGES_PATH
	
	echo "[sql]Start downloading data ..."
	cd $INSTALL_PACKAGES_PATH
	curl -O --fail $FTP_LINK/$sql_viper_lite_db
	[ $? -ne 0 ] && echo "[sql]$sql_viper_lite_db NOT FOUND"
	curl -O --fail $FTP_LINK/$sql_t_company
	[ $? -ne 0 ] && echo "[sql]$sql_t_company NOT FOUND"
	curl -O --fail $FTP_LINK/$sql_t_group
	[ $? -ne 0 ] && echo "[sql]$sql_t_group NOT FOUND"
	curl -O --fail $FTP_LINK/$sql_t_group_user
	[ $? -ne 0 ] && echo "[sql]$sql_t_group_user NOT FOUND"
	curl -O --fail $FTP_LINK/$sql_t_user
	[ $? -ne 0 ] && echo "[sql]$sql_t_user NOT FOUND"
	curl -O --fail $FTP_LINK/$sql_t_department
	[ $? -ne 0 ] && echo "[sql]$sql_t_department NOT FOUND"
	curl -O --fail $FTP_LINK/$sql_t_multi_feature
	[ $? -ne 0 ] && echo "[sql]$sql_t_multi_feature NOT FOUND"
	echo "[sql]Finished"
	
	echo "[sql]Start importing data into mysql database ..."
	mysql --protocol=tcp --host=localhost --user=senselink --port=$PORT --default-character-set=utf8 --comments --database=bi_slink_base < "$sql_t_company"
	echo "[sql]$sql_t_company `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysql --protocol=tcp --host=localhost --user=senselink --port=$PORT --default-character-set=utf8 --comments --database=bi_slink_base < "$sql_t_group"
	echo "[sql]$sql_t_group `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysql --protocol=tcp --host=localhost --user=senselink --port=$PORT --default-character-set=utf8 --comments --database=bi_slink_base < "$sql_t_group_user"
	echo "[sql]$sql_t_group_user `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysql --protocol=tcp --host=localhost --user=senselink --port=$PORT --default-character-set=utf8 --comments --database=bi_slink_base < "$sql_t_user"
	echo "[sql]$sql_t_user `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysql --protocol=tcp --host=localhost --user=senselink --port=$PORT --default-character-set=utf8 --comments --database=bi_slink_base < "$sql_t_department"
	echo "[sql]$sql_t_department `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysql --protocol=tcp --host=localhost --user=senselink --port=$PORT --default-character-set=utf8 --comments --database=bi_slink_base < "$sql_t_multi_feature"
	echo "[sql]$sql_t_multi_feature `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysql --protocol=tcp --host=localhost --user=senselink --port=$PORT --default-character-set=utf8 --comments --database=viper_lite < "$sql_viper_lite_db"
	echo "[sql]$sql_viper_lite_db `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	echo "[sql]Finished"
	
	echo "[afd]Start downloading data ..."
	[ ! -d  "$senselink_config_path/afd_data" ] && mkdir -p $senselink_config_path/afd_data
	cd $senselink_config_path/afd_data
	rm -rf *
	curl -O --fail $FTP_LINK/$package_afd
	[ $? -ne 0 ] && echo "[afd]$package_afd NOT FOUND"
	echo "[afd]Finished"
	echo "[afd]Start uncompressing data ..."
	tar -zxvf $package_afd > /dev/null 2>&1
	rm -rf $package_afd
	echo "[afd]Finished"
	
	#兼容老的没有迁移afd_data目录的情况
	[ ! -L $LINK_ROOT_PATH/viper-lite/bootstrap/afd/test/worker ] && ln -s $senselink_config_path/afd_data $LINK_ROOT_PATH/viper-lite/bootstrap/afd/test/worker
	
	cd $LINK_ROOT_PATH/viper-lite/bootstrap/afd && ./entrypoint.sh restart
	echo "[afd]Finished"
	
	echo "[senselink6base]Start downloading data ..."
	[ ! -d  "$senselink_config_path/picture" ] && mkdir -p $senselink_config_path/picture
	cd $senselink_config_path/picture
	curl -O --fail $FTP_LINK/$package_base
	[ $? -ne 0 ] && echo "[senselink6base]$package_base NOT FOUND"
	echo "[senselink6base]Finished"
	echo "[senselink6base]Start uncompressing data ..."
	tar -zxvf $package_base > /dev/null 2>&1 
	rm -rf $package_base
	echo "[senselink6base]Finished"
	
	#restart redis
	docker rm -f redis
	cd $LINK_ROOT_PATH/middleware/redis
	sh run.sh
	
	echo "Restore works are finished, please check below summary."
	echo "******************************************"
	db_id=`curl -s 'http://localhost:8188/v1/databases' | python3 -c "import sys, json; print(json.load(sys.stdin)['db_infos'][0]['db_id'])"`
	echo "feature db_id: "$db_id
	db_size=`curl -s 'http://localhost:8188/v1/databases/'$db_id | python3 -c "import sys, json; print(json.load(sys.stdin)['db_info']['indexes'][0]['size'])"`
	echo "feature size: "$db_size
	user_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -e "${sql_get_user_count}" | grep -v total`
	echo "t_user size: "$user_count
	static_features_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -e "${sql_get_static_features_count}" | grep -v total`	
	echo "static_features size: "$static_features_count

	
}

swap_seconds ()
{
	SEC=$1
	(( SEC < 60 )) && echo -e "[Elapsed time: $SEC seconds]"

	(( SEC >= 60 && SEC < 3600 )) && echo -e "[Elapsed time: $(( SEC / 60 )) \
	min $(( SEC % 60 )) sec]"

	(( SEC > 3600 )) && echo -e "[Elapsed time: $(( SEC / 3600 )) hr \
	$(( (SEC % 3600) / 60 )) min $(( (SEC % 3600) % 60 )) sec]"
}

#main function start from here
echo "Please choose to restore:"
echo "1 - 1w"
echo "2 - 150w"


read install_module

case $install_module in
	1)
        FTP_FOLDER_NAME="1w"
        ;;
	2)
        FTP_FOLDER_NAME="150w"
        ;;
    *)
        echo "No module is found"
		exit 2
esac

startTime=$(date '+%Y-%m-%d %H:%M:%S')
startTime_s=`date +%s`

edge

endTime=$(date '+%Y-%m-%d %H:%M:%S')
endTime_s=`date +%s`
sumTime=$[ $endTime_s - $startTime_s ]

echo "=================================================================="
swap_seconds $sumTime
