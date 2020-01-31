#!/bin/bash
#A StorJ node monitor script for telegraf using [inputs.exec]
#Visualizing StorJ V3 node health with Grafana

#Source: https://github.com/gsxryan/storj_telegraf_mon
#By turbostorjdsk (rocketchat) / KernelPanick (forum.storj.io)
#Help from BrightSilence, Alexey, Kiwwiaq, vedalken254, H3z (PRs), stefanbenten, robertstanfield, AndreiG6

#https://forum.storj.io/t/error-codes-what-they-mean-and-severity-level-read-first/518
#https://gist.github.com/gsxryan/d23de042fce21e5a3d895005e1aeafa7
#https://github.com/Kiwwiaq/storjv3logs/blob/master/storjlogs.sh
#https://github.com/ReneSmeekes/storj_success_rate

#Node Heath and Success Rates

#Log line can be edited using cat for SNO's who wrote their log to a file.
#using a rolling 24hr average, you may change to your desired rolling frequency
    #(less will vary more, longer will be more stable & tight)
    
CONTAINER_NAME="storagenode"
TIMEFRAME="24h"

LOG=$(mktemp)
docker logs --since $TIMEFRAME $CONTAINER_NAME > ${LOG} 2>&1

#LOG=$(eval "docker logs --since $TIMEFRAME $CONTAINER_NAME" 2>&1) # Not working $LOG is merged in one line
#LOG="awk -v d="$(date -d'24 hours ago' +'%FT%T')" '$1" "$2>=d' /mount1/storj/v3/data/node.log"

#Get Node ID (NOTE: Head-n15 may prove to be unreliable for users that may archive early parts of the file,
#since it's the fastest way, we'll leave it for now)
node_id=$(eval "docker logs $CONTAINER_NAME" 2>&1| head -n15 | awk -F' ' '/Node/ && /started/{print substr($4,0,7)}')
#NO_SUCH_CONTAINER_ERROR="Error: No such container: $CONTAINER_NAME"
#Cath if node ID collector fails (name Default)
if [ -z "$node_id" ]
  then node_id="Default"
fi

#count of unrecoverable failed audits
audit_failed_crit=$(grep -c 'failed.*GET_AUDIT.*open' $LOG)
#count of recoverable failed audits`
audit_failed_warn=$(grep -Pc 'failed.*GET_AUDIT(?!.*open)' $LOG)
#count of successful audits
audit_success=$(grep -c 'downloaded.*GET_AUDIT' $LOG)
#Ratio of Successful to Failed Audits
if [ "$(expr $audit_success + $audit_failed_crit + $audit_failed_warn)" == "0" ]
  then audit_ratio="100"
  else audit_ratio=$(awk 'BEGIN{printf "%0.3f\n",( "'$audit_success'" / ( "'$audit_success'" + "'$audit_failed_crit'" + "'$audit_failed_warn'" )) * 100 }')
fi

#GET: Failed Downloads from your node
dl_failed=$(grep -c 'download failed' $LOG)
#count of successful downloads
dl_success=$(grep -c 'downloaded.*GET' $LOG)
#Ratio of Failed Downloads
if [ "$(expr $dl_failed + $dl_success)" == "0" ]
  then dl_ratio="100"
  else dl_ratio=$(awk 'BEGIN{printf "%0.3f\n",( "'$dl_success'" / ( "'$dl_success'" + "'$dl_failed'" )) * 100 }')
fi
#count of started downloads (dl_started=audit_success+audit_failed_all+dl_success+dl_failed)
dl_started=$(grep -c 'download started' $LOG)

#PUT: count of failed uploads to your node
put_failed=$(grep -c 'upload failed' $LOG)
#count of successful uploads to your node
put_success=$(grep -c uploaded $LOG)
#Ratio of Uploads
if [ "$(expr $put_failed + $put_success)" == "0" ]
  then put_ratio="100"
  else put_ratio=$(awk 'BEGIN{printf "%0.3f\n",( "'$put_success'" / ( "'$put_success'" + "'$put_failed'" )) * 100 }')
fi
#count of started uploads (put_started=put_failed+put_success)
put_started=$(grep -c 'upload started' $LOG)

#Uploads: count of concurrent connection max
concurrent_limit=$(grep -c 'upload rejected' $LOG)
if [ "$(expr $concurrent_limit + $put_success)" == "0" ]
  then put_accept_ratio="100"
  else put_accept_ratio=$(awk 'BEGIN{printf "%0.3f\n",( "'$put_success'" / ( "'$put_success'" + "'$put_concurrent_limit'" )) * 100 }')
fi

#count of failed downloads of pieces for repair process
get_repair_failed=$(grep -c 'failed.*GET_REPAIR' $LOG)
#count of successful downloads of pieces for repair process
get_repair_success=$(grep -c 'downloaded.*GET_REPAIR' $LOG)
#Ratio of GET_REPAIR
if [ "$(expr $get_repair_success + $get_repair_failed)" == "0" ]
  then get_repair_ratio="100"
  else get_repair_ratio=$(awk 'BEGIN{printf "%0.3f\n",( "'$get_repair_success'" / ( "'$get_repair_success'" + "'$get_repair_failed'" )) * 100 }')
fi

#count of failed uploads repaired pieces
put_repair_failed=$(grep -c 'failed.*PUT_REPAIR' $LOG)
#count of successful uploads of repaired pieces
put_repair_success=$(grep -c 'uploaded.*PUT_REPAIR' $LOG)
#Ratio of PUT_REPAIR
if [ "$(expr $put_repair_success + $put_repair_failed)" == "0" ]
  then put_repair_ratio="100"
  else put_repair_ratio=$(awk 'BEGIN{printf "%0.3f\n",( "'$put_repair_success'" / ( "'$put_repair_success'" + "'$put_repair_failed'" )) * 100 }')
fi

#InfoDB Health Check, disk image is malformed
infodb_check=$(grep -c 'disk image is malformed' $LOG)
#Kademlia or DNS Health Check
kad_check=$(grep -c 'Error requesting voucher' $LOG)

#Collects Deleted Pieces
deleted=$(grep -c deleted $LOG)

#Checks for Node Reboot
reboots=$(grep -c 'Public server started on' $LOG)

#Checks latest node version reported
version=$(tac $LOG|grep -oPm1 '(?<=v)(\d{1,3}\.){2}\d{1,3}')

#CSV format export
#echo $(date +'%s'), $audit_ratio, $dl_ratio, $put_ratio, $put_accept_ratio, $get_repair_ratio, $put_repair_ratio, $concurrent_limit, $infodb_check, $kad_check >> successratio.log

#InfluxDB format export
echo "StorJHealth,NodeId=$node_id FailedCrit=$audit_failed_crit,FailedWarn=$audit_failed_warn,Success=$audit_success,Ratio=$audit_ratio,Deleted=$deleted $(date +'%s%N')"
#Newvedalken254
echo "StorJHealth,NodeId=$node_id DLFailed=$dl_failed,DLSuccess=$dl_success,DLRatio=$dl_ratio,PUTFailed=$put_failed,PUTSuccess=$put_success,PUTRatio=$put_ratio,PUTLimit=$concurrent_limit,PUTAcceptRatio=$put_accept_ratio,DLStarted=$dl_started,PUTStarted=$put_started $(date +'%s%N')"
#Repair
echo "StorJHealth,NodeId=$node_id GETRepairFail=$get_repair_failed,GETRepairSuccess=$get_repair_success,GETRepairRatio=$get_repair_ratio,PUTRepairFailed=$put_repair_failed,PUTRepairSuccess=$put_repair_success,PUTRepairRatio=$put_repair_ratio $(date +'%s%N')"
#Health
echo "StorJHealth,NodeId=$node_id InfoDBcheck=$infodb_check,VoucherCheck=$kad_check,Reboots=$reboots,Version=\"$version\" $(date +'%s%N')"

#Clean /tmp LOG created with $(mktemp)
rm $LOG
