#!/bin/bash
source ./config

HOSTNAME=$mysql_ip
PORT=$mysql_port
USERNAME=$mysql_user
PASSWORD=$mysql_password
echo $HOSTNAME:$PORT@$USERNAME:$PASSWORD
default_schedule_day=1
img_file_path=$senselink_config_path/picture
alarm_dir=senselink6alarm
recognition_dir=senselink6recognition
record_total=0
is_used_sql="select IFNULL(schedule_used,0) from bi_slink_base.t_schedule_config limit 1;"
is_used=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${is_used_sql}" | grep -v schedule_used`
if [ $is_used -eq 0 ]; then
	echo "Do not run this cleanup"
	exit 0
fi

cfg_sql="select IFNULL(schedule_day,$default_schedule_day) from bi_slink_base.t_schedule_config limit 1;"

schedule_day=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${cfg_sql}" | grep -v schedule_day` || schedule_day=$default_schedule_day
echo "delete $schedule_day days ago data"
if [ $schedule_day -lt 1 ]; then
    echo "the value is too small, use default value:$default_schedule_day!"
    schedule_day=$default_schedule_day
fi
clean_date=$(date -d"$schedule_day days ago" +%Y-%m-%d)

record_count_sql="select count(1) as total FROM bi_slink_base.t_record where sign_time_str < '$clean_date' ;"
operation_log_count_sql="select count(1) as total from bi_slink_base.t_operation_log where sign_time_str < '$clean_date' ;"
event_log_count_sql="select count(1) as total from bi_slink_base.t_event_log where create_at < '$clean_date' ;"
alarm_count_sql="select count(1) as total from bi_slink_base.t_alarm where create_at < '$clean_date' ;"
alarm_tarce_count_sql="select count(1) as total from bi_slink_base.t_alarm_trace where create_at < '$clean_date' ;"
attendance_result_count_sql="select count(1) as total from bi_slink_base.t_attendance_result where created_at < '$clean_date' ;"

record_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${record_count_sql}" | grep -v total`
operation_log_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${operation_log_count_sql}" | grep -v total`
event_log_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${event_log_count_sql}" | grep -v total`
alarm_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${alarm_count_sql}" | grep -v total`
alarm_trace_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${alarm_tarce_count_sql}" | grep -v total`
attendance_result_count=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${attendance_result_count_sql}" | grep -v total`
let record_total=$record_count+$operation_log_count+$event_log_count+$alarm_count+$alarm_trace_count+$attendance_result_count

delete_record_sql="DELETE FROM bi_slink_base.t_record where sign_time_str < '$clean_date' ;"
delete_operation_log_sql="delete from bi_slink_base.t_operation_log where sign_time_str < '$clean_date' ;"
get_last_record_sql="select id FROM bi_slink_base.t_record order by id ASC limit 1;"
delete_event_log="delete from bi_slink_base.t_event_log where create_at < '$clean_date' ;"
delete_alarm="delete from bi_slink_base.t_alarm where create_at < '$clean_date' ;"
delete_alarm_tarce="delete from bi_slink_base.t_alarm_trace where create_at < '$clean_date' ;"
delete_attendance_result="delete from bi_slink_base.t_attendance_result where created_at < '$clean_date' ;"
echo "clean_date=$clean_date, clean expired record starting ..."

echo "step 1 : delete picture"

echo "start to delete before $clean_date images"

find $img_file_path/$alarm_dir/ -mindepth 1 -mtime +$schedule_day -exec rm -rf {} \;
find $img_file_path/$recognition_dir/ -mindepth 1 -mtime +$schedule_day -exec rm -rf {} \;

echo "delete img files complete"

echo "$(date '+%F %T') start delete t_record"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "$delete_record_sql"
echo "$(date '+%F %T') start delete t_operation_log"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "$delete_operation_log_sql"
echo "get last record_id is:"
last_record_id=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${get_last_record_sql}" | grep -v id`
echo $last_record_id

if [ $last_record_id ]; then
	data_collector_record=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "select count(1) as total from bi_slink_base.t_data_collector where record_id < $last_record_id"|grep -v total`
	let record_total_all=$record_total+$data_collector_record
	echo "$(date '+%F %T') start delete t_data_controller"
	mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "delete from bi_slink_base.t_data_collector where record_id < $last_record_id"
else	
	let record_total_all=$record_total
fi	
echo "$(date '+%F %T') start delete t_event_log"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${delete_event_log}"		
echo "$(date '+%F %T') start delete t_alarm"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${delete_alarm}"
echo "$(date '+%F %T') start delete t_alarm_trace"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${delete_alarm_tarce}"
echo "$(date '+%F %T') start delete t_attendance_result"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${delete_attendance_result}"

today=`date +%Y-%m-%d`
info="aim:$today,total:$record_total_all"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "insert into bi_slink_base.t_schedule_log(date,info,company_id) values ('$today','$info',1)"

echo "$(date '+%F %T') do clean success! total:$record_total_all"
