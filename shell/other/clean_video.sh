#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
#set -x
SHELL_INSTALL_PATH=/home/rundir/shell
source $SHELL_INSTALL_PATH/config

HOSTNAME=$mysql_ip
PORT=$mysql_port
USERNAME=$mysql_user
PASSWORD=$mysql_password
#echo $HOSTNAME:$PORT@$USERNAME:$PASSWORD
default_save_days=30
video_file_path=/home/rundir/video
let total_file_cnt=0
db_record_cnt=0

# 获取清理策略的系统配置
cfg_sql="SELECT IFNULL(MAX(video_save), $default_save_days) FROM bi_slink_base.t_company_video_config"
save_days=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${cfg_sql}" | grep -v video_save` || save_days=$default_save_days
if test -z "$save_days"; then
    echo "$(date '+%F %T') save_days:$save_days : the value is null, use default value:$default_save_days!"
    save_days=$default_save_days
fi

if [ $save_days -lt 1 ]; then
    echo "$(date '+%F %T') save_days:$save_days : the value is too small, use default value:$default_save_days!"
    save_days=$default_save_days
fi

# 计算数据应清理到哪一天
clean_date=$(date -d"$save_days day ago" +%Y%m%d);

# sql语句初始化
record_sql="SELECT COUNT(*) FROM bi_slink_base.t_video  WHERE clip_date < STR_TO_DATE('$clean_date', '%Y%m%d')"
delete_rel_sql="DELETE FROM bi_slink_base.t_video_relation a WHERE EXISTS (SELECT 1 FROM bi_slink_base.t_video b WHERE b.clip_date < STR_TO_DATE('$clean_date', '%Y%m%d') AND a.video_id=b.id)"
delete_video_sql="DELETE FROM bi_slink_base.t_video  WHERE clip_date < STR_TO_DATE('$clean_date', '%Y%m%d')"

# 开始清理
echo "$(date '+%F %T') save_days:$save_days, clean_date=$clean_date, video_file_path: $video_file_path; clean expired video files starting ..."
#1. 清理文件
ls $video_file_path > /tmp/.video_file_path_list
while read date_dir
do
    if [ $date_dir -lt $clean_date ]; then
                video_file_cnt=`ls $video_file_path/$date_dir|wc -l`
                if [ $video_file_cnt -gt 0 ]; then
                        echo "$(date '+%F %T') clean date:$date_dir, file count: $video_file_cnt"
                        let total_file_cnt=$total_file_cnt+$video_file_cnt
                else
                        echo "$(date '+%F %T') clean date:$date_dir, file count: $video_file_cnt; no file need to clean"
                fi
                rm -r $video_file_path/$date_dir
        fi
done < "/tmp/.video_file_path_list"

# 2. 清理数据库
if [ $total_file_cnt -gt 0 ]; then
    db_record_cnt=`mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${record_sql}" | grep -v COUNT`
        # delete t_video_relation
        echo "$(date '+%F %T') start delete t_video_relation"
    mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${delete_rel_sql}"
        # delete t_video
        echo "$(date '+%F %T') start delete t_video"
    mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${delete_video_sql}"
fi


# 完成
echo "$(date '+%F %T') do clean success! clean total_file_cnt:$total_file_cnt, db_record_cnt:$db_record_cnt"
echo "=================================================================="
