#A StorJ node monitor script by turbostorjdsk / KernelPanick
#Node Success Rates

#count of unrecoverable failed audits
audit_failed_crit=$(sudo docker logs storagenode 2>&1 | grep GET_AUDIT | grep failed | grep open -c)
if [ $audit_failed_crit -ge 1 ]
        then echo CRITICAL: Unrecoverable Failed Audits: $audit_failed_crit
        fi
#count of recoverable failed audits`
audit_failed_warn=$(sudo docker logs storagenode 2>&1 | grep GET_AUDIT | grep failed | grep -v open -c)
if [ $audit_failed_warn -ge 1 ]
        then echo WARNING: Recoverable Failed Audits: $audit_failed_warn
        fi
#count of successful audits
audit_success=$(sudo docker logs storagenode 2>&1 | grep GET_AUDIT | grep downloaded -c)
#Ratio of Successful to Failed Audits
audit_ratio=$(printf '%.3f\n' $(echo "(($audit_success/($audit_failed_crit+$audit_failed_warn+$audit_success))*100)" | bc -l))
echo Audit Success Rate: $audit_ratio%

#Failed Downloads from your node
dl_failed=$(sudo docker logs storagenode 2>&1 | grep '"GET"' | grep failed -c)
#count of successful downloads
dl_success=$(sudo docker logs storagenode 2>&1 | grep '"GET"' | grep downloaded -c)
#Ratio of Failed Downloads
dl_ratio=$(printf '%.3f\n' $(echo "(($dl_success/($dl_failed+$dl_success))*100)" | bc -l))
echo Download Success Rate: $dl_ratio%

#count of failed uploads to your node
put_failed=$(sudo docker logs storagenode 2>&1 | grep '"PUT"' | grep failed -c)
#count of successful uploads to your node
put_success=$(sudo docker logs storagenode 2>&1 | grep '"PUT"' | grep uploaded -c)
#Ratio of Uploads
put_ratio=$(printf '%.3f\n' $(echo "(($put_success/($put_failed+$put_success))*100)" | bc -l))
echo Upload Success Rate: $put_ratio%

#count of failed downloads of pieces for repair process
get_repair_failed=$(sudo docker logs storagenode 2>&1 | grep GET_REPAIR | grep failed -c)
#count of successful downloads of pieces for repair process
get_repair_success=$(sudo docker logs storagenode 2>&1 | grep GET_REPAIR | grep downloaded -c)
#Ratio of GET_REPAIR
get_repair_ratio=$(printf '%.3f\n' $(echo "(($get_repair_success/($get_repair_failed+$get_repair_success))*100)" | bc -l))
echo Repair Download Success Rate: $get_repair_ratio%

#count of failed uploads repaired pieces
put_repair_failed=$(sudo docker logs storagenode 2>&1 | grep PUT_REPAIR | grep failed -c)
#count of successful uploads of repaired pieces
put_repair_success=$(sudo docker logs storagenode 2>&1 | grep PUT_REPAIR | grep uploaded -c)
#Ratio of PUT_REPAIR
put_repair_ratio=$(printf '%.3f\n' $(echo "(($put_repair_success/($put_repair_failed+$put_repair_success))*100)" | bc -l))
echo Repair Upload Success Rate: $put_repair_ratio%

#count of concurrent connection max
concurrent_limit=$(sudo docker logs storagenode 2>&1 | grep "upload rejected" -c)

echo $(date +'%s'), $audit_ratio, $dl_ratio, $put_ratio, $get_repair_ratio, $put_repair_ratio, $concurrent_limit >> SuccessRatio.log