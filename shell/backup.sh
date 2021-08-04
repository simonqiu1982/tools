#!/bin/bash
echo "=================================================================="
set +x
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

edge(){
	LINK_ROOT_PATH="/data/senselink-edge-all"
	
	[ ! -d  "$LINK_ROOT_PATH" ] && echo "No link platform installed: $LINK_ROOT_PATH" && exit 2
	[ ! -f  $LINK_ROOT_PATH/config ] && echo "No config file exists: $LINK_ROOT_PATH/config" && exit 2
	source $LINK_ROOT_PATH/config
	[ ! -d  "$senselink_config_path" ] && echo "No config directory found: $senselink_config_path" && exit 2
	
	INSTALL_PACKAGES_PATH="$senselink_config_path/packages/backup"
	
	package_afd="afd.tar.gz"
	package_base="senselink6base.tar.gz"
	sql_viper_lite_db="viper_lite_db.sql"
	sql_t_company="t_company.sql"
	sql_t_group="t_group.sql"
	sql_t_group_user="t_group_user.sql"
	sql_t_user="t_user.sql"
	sql_t_department="t_department.sql"
	sql_t_multi_feature="t_multi_feature.sql"
	
	HOSTNAME=$mysql_ip
	PORT=$mysql_port
	USERNAME=$mysql_user
	PASSWORD=$mysql_password
	echo $HOSTNAME:$PORT@$USERNAME:$PASSWORD
	export MYSQL_PWD=$PASSWORD
	
	
	[ -d  "$INSTALL_PACKAGES_PATH" ] && rm -rf "$INSTALL_PACKAGES_PATH"
	mkdir -p $INSTALL_PACKAGES_PATH
	
	echo "[sql]Start backup data ..."
	cd $INSTALL_PACKAGES_PATH
	
	mysqldump  --host=localhost --port=$PORT --default-character-set=utf8 --user=senselink --protocol=tcp --skip-triggers --no-tablespaces "bi_slink_base" "t_company" --result-file=$sql_t_company
	echo "[sql]$sql_t_company `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysqldump  --host=localhost --port=$PORT --default-character-set=utf8 --user=senselink --protocol=tcp --skip-triggers --no-tablespaces "bi_slink_base" "t_multi_feature" --result-file=$sql_t_multi_feature
	echo "[sql]$sql_t_multi_feature `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysqldump  --host=localhost --port=$PORT --default-character-set=utf8 --user=senselink --protocol=tcp --skip-triggers --no-tablespaces "bi_slink_base" "t_group" --result-file=$sql_t_group
	echo "[sql]$sql_t_group `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysqldump  --host=localhost --port=$PORT --default-character-set=utf8 --user=senselink --protocol=tcp --skip-triggers --no-tablespaces "bi_slink_base" "t_group_user" --result-file=$sql_t_group_user
	echo "[sql]$sql_t_group_user `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysqldump  --host=localhost --port=$PORT --default-character-set=utf8 --user=senselink --protocol=tcp --skip-triggers --no-tablespaces "bi_slink_base" "t_user" --result-file=$sql_t_user
	echo "[sql]$sql_t_user `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysqldump  --host=localhost --port=$PORT --default-character-set=utf8 --user=senselink --protocol=tcp --skip-triggers --no-tablespaces "bi_slink_base" "t_department" --result-file=$sql_t_department
	echo "[sql]$sql_t_department `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	mysqldump  --host=localhost --port=$PORT --default-character-set=utf8 --user=senselink --protocol=tcp --databases viper_lite --no-tablespaces --result-file=$sql_viper_lite_db
	echo "[sql]$sql_viper_lite_db `[ $? -ne 0 ] && echo 'error' || echo 'ok'`"
	echo "[sql]Finished"
	
	echo "[afd]Start backup data ..."
	if [ -d  "$senselink_config_path/afd_data" ]; then
		cd $senselink_config_path/afd_data/logs/rs-0/0/
		md5sum *.wal > 0.md5
		cd $senselink_config_path/afd_data
		tar -zcvf $INSTALL_PACKAGES_PATH/$package_afd * > /dev/null 2>&1
	elif [ -d  "$LINK_ROOT_PATH/viper-lite/bootstrap/afd/test/worker" ]; then
		cd $LINK_ROOT_PATH/viper-lite/bootstrap/afd/test/worker/logs/rs-0/0/
		md5sum *.wal > 0.md5
		cd $LINK_ROOT_PATH/viper-lite/bootstrap/afd/test/worker
		tar -zcvf $INSTALL_PACKAGES_PATH/$package_afd * > /dev/null 2>&1
	else
		echo "No afd data directory found: $senselink_config_path/afd_data, $LINK_ROOT_PATH/viper-lite/bootstrap/afd/test/worker"
	fi
	echo "[afd]Finished"
	
	echo "[senselink6base]Start backup data ..."
	if [ -d  "$senselink_config_path/picture/senselink6base" ]; then
		cd $senselink_config_path/picture/
		tar -zcvf $INSTALL_PACKAGES_PATH/$package_base senselink6base > /dev/null 2>&1
	else
		echo "No senselink6base data directory found: $senselink_config_path/picture/senselink6base"
	fi 
	echo "[senselink6base]Finished"
	echo "Backup works are finished, please check below summary."
	echo "******************************************"
	cd $INSTALL_PACKAGES_PATH && pwd && ls -hlrt

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


startTime=$(date '+%Y-%m-%d %H:%M:%S')
startTime_s=`date +%s`

edge

endTime=$(date '+%Y-%m-%d %H:%M:%S')
endTime_s=`date +%s`
sumTime=$[ $endTime_s - $startTime_s ]

echo "=================================================================="
swap_seconds $sumTime
