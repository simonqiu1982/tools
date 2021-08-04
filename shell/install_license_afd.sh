#!/bin/bash
echo "=================================================================="
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
set +x

FTP_HOST="10.152.244.7"
FTP_FOLDER_NAME="200w"
FTP_URI="download/license"
DB_SIZE=2000000


install(){
	LINK_ROOT_PATH="/data/senselink-edge-all"
	VIPER_LITE_ROOT="$LINK_ROOT_PATH/viper-lite"
	
	[ ! -d  "$LINK_ROOT_PATH" ] && echo "No link platform installed: $LINK_ROOT_PATH" && exit 2
	[ ! -d $VIPER_LITE_ROOT ] && echo "No viper lite exists: $VIPER_LITE_ROOT" && exit 2
	[ ! -f $LINK_ROOT_PATH/config ] && echo "No config file exists: $LINK_ROOT_PATH/config" && exit 2
	source $LINK_ROOT_PATH/config
	[ ! -d  "$senselink_config_path" ] && echo "No config directory found: $senselink_config_path" && exit 2
	
	client_lic="client.lic"
	client_pem="client.pem"
	cluster_lic="cluster.lic"
	
	FTP_LINK="http://$FTP_HOST/$FTP_URI/$FTP_FOLDER_NAME"
	
	HOSTNAME=$mysql_ip
	PORT=$mysql_port
	USERNAME=$mysql_user
	PASSWORD=$mysql_password
	echo $HOSTNAME:$PORT@$USERNAME:$PASSWORD
	export MYSQL_PWD=$PASSWORD
	
	echo "Start downloading data ..."
	cd $VIPER_LITE_ROOT/infra/config/licenseca
	curl -O --fail $FTP_LINK/$client_lic
	[ $? -ne 0 ] && echo "$client_lic NOT FOUND"
	curl -O --fail $FTP_LINK/$client_pem
	[ $? -ne 0 ] && echo "$client_pem NOT FOUND"
	curl -O --fail $FTP_LINK/$cluster_lic
	[ $? -ne 0 ] && echo "$cluster_lic NOT FOUND"
	echo "Finished"
	
	cd $VIPER_LITE_ROOT/infra/bin
	./license_client status
	echo ""
	
	create_afd_db="curl -H "Content-Type:application/json" -X POST -d "{\"name\":\"$(date +%s%N)\",\"object_type\":\"face\",\"feature_version\":\"25000\",\"description\":\"performance\",\"db_size\":\"$DB_SIZE\",\"options\":{\"enable_feature_cache\":false}}" http://localhost:8188/v1/databases"
	response=`$create_afd_db`
	while [[ "$response" == *"db error"* ]]
	do
		sleep 1s
		response=`$create_afd_db`
	done
	
	db_id=`echo $response | python3 -c "import sys, json; print(json.load(sys.stdin)['db_id'])"` 
	echo ""
	echo "db_id is created:$db_id"
	
	[ ! $db_id ] && echo "db_id is NULL" && exit 2
	
	sql_update_viper_db_id="update bi_slink_base.t_company set viper_db_id='$db_id';"
	sql_get_viper_db_id="select viper_db_id from bi_slink_base.t_company limit 1;"
	
	mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -e "${sql_update_viper_db_id}"
	viper_db_id=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -e "${sql_get_viper_db_id}" | grep -v viper_db_id`
	
	echo ""
	echo "Restarting link and viper lite..."
	[ -d $LINK_ROOT_PATH ] && cd $LINK_ROOT_PATH && sh stop.sh
	[ `docker ps -aq | wc -l` -ne 0 ] && docker rm -f $(docker ps -aq)
	[ -d $LINK_ROOT_PATH ] && cd $LINK_ROOT_PATH && sh start.sh
	
	echo "Finished, please check below summary."
	echo "******************************************"
	echo "db_id: $db_id"
	echo "t_company_viper_db_id: $viper_db_id"
	[ $viper_db_id == $db_id ] && echo "Done" || echo "error!!!"
	
	db_response=`curl -s 'http://localhost:8188/v1/databases/'$db_id`
	while [[ "$db_response" == *"db error"* ]]
	do
		sleep 1s
		db_response=`curl -s 'http://localhost:8188/v1/databases/'$db_id`
	done
	
	max_size=`echo $db_response | python3 -c "import sys, json; print(json.load(sys.stdin)['db_info']['max_size'])"`
	
	echo "feature size: "$max_size
	
	
	
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

startTime=$(date '+%Y-%m-%d %H:%M:%S')
startTime_s=`date +%s`

install

endTime=$(date '+%Y-%m-%d %H:%M:%S')
endTime_s=`date +%s`
sumTime=$[ $endTime_s - $startTime_s ]

echo "=================================================================="
swap_seconds $sumTime
