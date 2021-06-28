#!/bin/bash

proclist=(stpuhald nvr-clip operate-manage-service video-process-service-manager-0 video-process-service-worker-0 video-process-service-worker-1 video-process-service-worker-2 video-process-service-worker-3 engine-image-process-service shard-proxy shard-worker engine-video-rtsp-service engine-broker-sip-service rtsp-over-ws engine-api-wrapper-service object-storage-gateway /go/app/feature mercury-media-server ./ota ./attendance ./application /emqx/erts-10.7.1/bin/beam.smp mysqld /bin/etcd /bin/zetcd redis-server )

trim()
{
    trimmed=$1
    trimmed=${trimmed%% }
    trimmed=${trimmed## }
    echo $trimmed
}

date
dt=`date '+%F %T'`
total=0
for proc in "${proclist[@]}"; do
    #pid=`ps|grep $proc|grep -v grep|grep -v entrypoint|awk  '{print $1}'`
    pid=`ps -ef|grep $proc|grep -v grep|grep -v entrypoint|awk  '{print $2}'`
    #cnt=`ps|grep $proc|grep -v grep|grep -v entrypoint|wc -l`
    cnt=`ps -ef|grep $proc|grep -v grep|grep -v entrypoint|wc -l`
    if [ $cnt = 0 ]; then
        continue
    fi

    memory=`cat /proc/$pid/status|grep RSS|awk -F":" '{print $2}'` && :
    echo "$dt $cnt $pid $proc : $memory"
    let total=$total+$(trim ${memory%kB})

done


#ps|grep java|grep -v grep|awk  '{print $1}' > .tmp_java_pid.list
ps -ef|grep java|grep -v grep|awk  '{print $2}' > .tmp_java_pid.list

while read pid
do
    memory=`cat /proc/$pid/status|grep RSS|awk -F":" '{print $2}'` && :
    echo "$dt 1 $pid java : $memory"
    let total=$total+$(trim ${memory%kB})
done < ".tmp_java_pid.list"
echo "======================================"
echo "$dt total=$total KB"
let total=$total/1024
echo "$dt total=$total MB"
