#!/bin/bash
#A StorJ node monitor script for telegraf using [inputs.exec]
#Visualizing StorJ V3 node health with Grafana

#Source: https://github.com/gsxryan/storj_telegraf_mon
#By turbostorjdsk (rocketchat) / KernelPanick (forum.storj.io)
#Help from BrightSilence, Alexey, Kiwwiaq, vedalken254, H3z (PRs)

#https://forum.storj.io/t/error-codes-what-they-mean-and-severity-level-read-first/518
#https://gist.github.com/gsxryan/d23de042fce21e5a3d895005e1aeafa7
#https://github.com/Kiwwiaq/storjv3logs/blob/master/storjlogs.sh
#https://github.com/ReneSmeekes/storj_success_rate

#Node Heath and Success Rates

#Log line can be edited using cat for SNO's who wrote their log to a file.
#using a rolling 24hr average, you may change to your desired rolling frequency
    #(less will vary more, longer will be more stable & tight)
LOG="docker logs --since 24h storagenode"
#LOG="awk -v d="$(date -d'24 hours ago' +'%FT%T')" '$1" "$2>=d' /mount1/storj/v3/data/node.log"

#count of unrecoverable failed audits
audit_failed_crit=$($LOG 2>&1 | grep GET_AUDIT | grep failed | grep open -c)
#count of recoverable failed audits`
audit_failed_warn=$($LOG 2>&1 | grep GET_AUDIT | grep failed | grep -v open -c)
#count of successful audits
audit_success=$($LOG 2>&1 | grep GET_AUDIT | grep downloaded -c)
#Ratio of Successful to Failed Audits
if [ "$(echo "$audit_success $audit_failed_crit $audit_failed_warn" | awk '{print ( $1 + $2 + $3 )}')" == "0" ]
  then audit_ratio="100"
  else audit_ratio=$(printf '%.3f\n' $(echo "$audit_success $audit_failed_crit $audit_failed_warn" | awk '{print ( $1 / ( $1 + $2 + $3 )) * 100 }'))
fi


#Failed Downloads from your node
dl_failed=$($LOG 2>&1 | grep '"GET"' | grep failed -c)
#count of successful downloads
dl_success=$($LOG 2>&1 | grep '"GET"' | grep downloaded -c)
#Ratio of Failed Downloads
if [ "$(echo "$dl_failed $dl_success" | awk '{print ( $1 + $2 )}')" == "0" ]
  then dl_ratio="100"
  else dl_ratio=$(printf '%.3f\n' $(echo "$dl_success $dl_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))
fi

#count of failed uploads to your node
put_failed=$($LOG 2>&1 | grep '"PUT"' | grep failed -c)
#count of successful uploads to your node
put_success=$($LOG 2>&1 | grep '"PUT"' | grep uploaded -c)
#Ratio of Uploads
if [ "$(echo "$put_failed $put_success" | awk '{print ( $1 + $2 )}')" == "0" ]
  then put_ratio="100"
  else put_ratio=$(printf '%.3f\n' $(echo "$put_success $put_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))
fi

#Uploads: count of concurrent connection max
concurrent_limit=$($LOG 2>&1 | grep "upload rejected" -c)
if [ "$(echo "$concurrent_limit $put_success" | awk '{print ( $1 + $2 )}')" == "0" ]
  then put_accept_ratio="100"
  else put_accept_ratio=$(printf '%.3f\n' $(echo "$put_success $concurrent_limit" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))
fi

#count of failed downloads of pieces for repair process
get_repair_failed=$($LOG 2>&1 | grep GET_REPAIR | grep failed -c)
#count of successful downloads of pieces for repair process
get_repair_success=$($LOG 2>&1 | grep GET_REPAIR | grep downloaded -c)
#Ratio of GET_REPAIR
if [ "$(echo "$get_repair_success $get_repair_failed" | awk '{print ( $1 + $2 )}')" == "0" ]
  then get_repair_ratio="100"
  else get_repair_ratio=$(printf '%.3f\n' $(echo "$get_repair_success $get_repair_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))
fi

#count of failed uploads repaired pieces
put_repair_failed=$($LOG 2>&1 | grep PUT_REPAIR | grep failed -c)
#count of successful uploads of repaired pieces
put_repair_success=$($LOG 2>&1 | grep PUT_REPAIR | grep uploaded -c)
#Ratio of PUT_REPAIR
if [ "$(echo "$put_repair_success $put_repair_failed" | awk '{print ( $1 + $2 )}')" == "0" ]
  then put_repair_ratio="100"
  else put_repair_ratio=$(printf '%.3f\n' $(echo "$put_repair_success $put_repair_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))
fi

#InfoDB Health Check, disk image is malformed
infodb_check=$($LOG 2>&1 | grep "disk image is malformed" -c)
#Kademlia or DNS Health Check
kad_check=$($LOG 2>&1 | grep "Error requesting voucher" -c)

#Collects Deleted Pieces
deleted=$($LOG 2>&1 | grep "deleted" -c)

#Checks for Node Reboot
reboots=$($LOG 2>&1 | grep "Public server started on" -c)

#CSV format export
#echo $(date +'%s'), $audit_ratio, $dl_ratio, $put_ratio, $put_accept_ratio, $get_repair_ratio, $put_repair_ratio, $concurrent_limit, $infodb_check, $kad_check >> successratio.log

#InfluxDB format export
echo "StorJHealth,stat=audit FailedCrit=$audit_failed_crit,FailedWarn=$audit_failed_warn,Success=$audit_success,Ratio=$audit_ratio,Deleted=$deleted $(date +'%s%N')"
#Newvedalken254
echo "StorJHealth,stat=new DLFailed=$dl_failed,DLSuccess=$dl_success,DLRatio=$dl_ratio,PUTFailed=$put_failed,PUTSuccess=$put_success,PUTRatio=$put_ratio,PUTLimit=$concurrent_limit,PUTAcceptRatio=$put_accept_ratio $(date +'%s%N')"
#Repair
echo "StorJHealth,stat=repair GETRepairFail=$get_repair_failed,GETRepairSuccess=$get_repair_success,GETRepairRatio=$get_repair_ratio,PUTRepairFailed=$put_repair_failed,PUTRepairSuccess=$put_repair_success,PUTRepairRatio=$put_repair_ratio $(date +'%s%N')"
#Health
echo "StorJHealth,stat=health InfoDBcheck=$infodb_check,VoucherCheck=$kad_check,Reboots=$reboots $(date +'%s%N')"