#!/bin/bash
source ./config

HOSTNAME=$mysql_ip
PORT=$mysql_port
USERNAME=$mysql_user
PASSWORD=$mysql_password
echo $HOSTNAME:$PORT@$USERNAME:$PASSWORD
schedule_day=30
img_file_path=$senselink_config_path/picture
collector_dir=senselink6collector
is_used_sql="select IFNULL(save_collector,1) from bi_slink_base.t_company_config limit 1;"
is_used=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${is_used_sql}" | grep -v save_collector`
if [ $is_used -eq 0 ]; then
	echo "do not save the collector"
	schedule_day=1
fi

clean_date=$(date -d"$schedule_day days ago" +%Y-%m-%d)

collector_count_sql="select count(1) as total from bi_slink_base.t_data_collector where create_at < '$clean_date' ;"
record_total=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${collector_count_sql}"|grep -v total`

delete_collector_sql="DELETE FROM bi_slink_base.t_data_collector where create_at < '$clean_date' ;"

echo "clean_date=$clean_date, clean expired collector data starting,total record ${record_total} ..."

echo "step 1: delete picture"

echo "start to delete $schedule_day days ago images"

find $img_file_path/$collector_dir/ -mindepth 1 -mtime +$schedule_day -exec rm -rf {} \;

echo "delete img files complete"

echo "$(date '+%F %T') start delete t_data_collector"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "$delete_collector_sql"

echo "$(date '+%F %T') do clean success!"
