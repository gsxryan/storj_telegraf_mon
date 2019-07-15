#A StorJ node monitor script for telegraf using [inputs.exec]
#By turbostorjdsk / KernelPanick
#Help from BrightSilence, Alexey, Kiwwiaq

#Node Success Rates

#Log line can be edited using cat for SNO's who wrote their log to a file.
#using a rolling 24hr average, you may change to your desired rolling frequency
    #(less will vary more, longer will be more stable & tight)
LOG="docker logs --since 24h storagenode"
#LOG="cat /volume1/storj/v3/data/node.log"

#count of unrecoverable failed audits
audit_failed_crit=$($LOG 2>&1 | grep GET_AUDIT | grep failed | grep open -c)
#count of recoverable failed audits`
audit_failed_warn=$($LOG 2>&1 | grep GET_AUDIT | grep failed | grep -v open -c)
#count of successful audits
audit_success=$($LOG 2>&1 | grep GET_AUDIT | grep downloaded -c)
#Ratio of Successful to Failed Audits
audit_ratio=$(printf '%.3f\n' $(echo -e "$audit_success $audit_failed_crit $audit_failed_warn" | awk '{print ( $1 / ( $1 + $2 + $3 )) * 100 }'))


#Failed Downloads from your node
dl_failed=$($LOG 2>&1 | grep '"GET"' | grep failed -c)
#count of successful downloads
dl_success=$($LOG 2>&1 | grep '"GET"' | grep downloaded -c)
#Ratio of Failed Downloads
dl_ratio=$(printf '%.3f\n' $(echo -e "$dl_success $dl_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))

#count of failed uploads to your node
put_failed=$($LOG 2>&1 | grep '"PUT"' | grep failed -c)
#count of successful uploads to your node
put_success=$($LOG 2>&1 | grep '"PUT"' | grep uploaded -c)
#Ratio of Uploads
put_ratio=$(printf '%.3f\n' $(echo -e "$put_success $put_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))
#Uploads: count of concurrent connection max
concurrent_limit=$($LOG 2>&1 | grep "upload rejected" -c)
put_accept_ratio=$(printf '%.3f\n' $(echo -e "$put_success $concurrent_limit" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))

#count of failed downloads of pieces for repair process
get_repair_failed=$($LOG 2>&1 | grep GET_REPAIR | grep failed -c)
#count of successful downloads of pieces for repair process
get_repair_success=$($LOG 2>&1 | grep GET_REPAIR | grep downloaded -c)
#Ratio of GET_REPAIR
get_repair_ratio=$(printf '%.3f\n' $(echo -e "$get_repair_success $get_repair_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))

#count of failed uploads repaired pieces
put_repair_failed=$($LOG 2>&1 | grep PUT_REPAIR | grep failed -c)
#count of successful uploads of repaired pieces
put_repair_success=$($LOG 2>&1 | grep PUT_REPAIR | grep uploaded -c)
#Ratio of PUT_REPAIR
put_repair_ratio=$(printf '%.3f\n' $(echo -e "$put_repair_success $put_repair_failed" | awk '{print ( $1 / ( $1 + $2 )) * 100 }'))

#InfoDB Health Check, disk image is malformed
infodb_check=#($LOG 2>&1 | grep "disk images is malformed" -c)

echo $(date +'%s'), $audit_ratio, $dl_ratio, $put_ratio, $get_repair_ratio, $put_repair_ratio, $concurrent_limit >> SuccessRatio.log