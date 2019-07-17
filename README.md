# storj_telegraf_mon
Success Rates output using StorJ logs with telegraf [inputs.exec] to InfluxDB format.

## Installation
Add/Append this block to your telegraf.conf
```
 [[inputs.exec]]
   commands = ["/path/to/scripts/successrate.sh" ] #some configs may need "sh " before /
   timeout = "180s" #If you want to run faster than 180s be sure to change this
   interval = "30m" #Comment this out if you already declare it earlier in the config.
   #name_suffix = "_foo" # Will result as "StorjHealth_foo" Uploaded dashboard will not use
   data_format = "influx"
```
Don't forget to `chmod +x successrate.sh`
