# storj_telegraf_mon
Success Rates output using StorJ logs with telegraf [inputs.exec] to InfluxDB format.

## Installation
Add this block to your telegraf.conf
```
 [[inputs.exec]]
   commands = ["/path/to/scripts/successrate.sh" ]
   timeout = "60s"
   interval = "30m"
   name_suffix = "_storj_successrate" # Will result as "exec_storj_successrate", check your Grafana dashboard config
   data_format = "influx"
```
Don't forget to `chmod +x successrate.sh`
