# storj_telegraf_mon
Success Rates output using StorJ logs with telegraf [inputs.exec] to InfluxDB format.
Dashboard values extracted from Storage Node API.

## Installation
Open your Storage Node API by adding this:
``-p 14002:14002`` to your run command of your Storage Node.

Add/Append this block to your telegraf.conf
  
- StorJ Node Items (default InfluxDB 'StorJ')
```
 [[inputs.exec]]
   commands = ["/path/to/scripts/successrate.sh" ] #some configs may need "sh " before /
   timeout = "180s" #If you want to run faster than 180s be sure to change this
   interval = "30m" #Comment this out if you already declare it earlier in the config.
   #name_suffix = "_foo" # Will result as "StorjHealth_foo" Uploaded dashboard will not use
   data_format = "influx"

 [[inputs.exec]]
   commands = ["/path/to/scripts/tokens.sh" ] #some configs may need "sh " before /
   timeout = "60s"
   interval = "1h" # if you don't care to track STORJ price, you can increase it to 24h
   data_format = "influx"

  [[inputs.exec]]
     commands = [
          "curl -s 127.0.0.1:14002/api/dashboard", # Open SNO API by mapping ports when running your SNO docker instance
          "curl -s 127.0.0.1:14003/api/dashboard" # If multiple nodes, map ports accordingly
          ]
     timeout = "60s"
     interval = "1m"
     data_format = "json"
     tag_keys = [ "data_nodeID" ]
     name_override = "StorJHealth"
```

- Host Items (default InfluxDB 'telegraf')
```
# Read metrics about cpu usage
[[inputs.cpu]]
  ## Whether to report per-cpu stats or not
  percpu = true
  ## Whether to report total system cpu stats or not
  totalcpu = true
  ## If true, collect raw CPU time metrics.
  collect_cpu_time = false
  ## If true, compute and report the sum of all non-idle CPU states.
  report_active = false
  ```
  ```
  [[inputs.disk]]
  ## By default stats will be gathered for all mount points.
  ## Set mount_points will restrict the stats to only the specified mount points.
  # mount_points = ["/"]

  ## Ignore mount points by filesystem type.
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "overlay", "aufs", "squashfs"]
  ```
  ```
  [[inputs.diskio]]
   ## IOPS Monitor
   ```
  ```
  [[inputs.mem]]
  ## RAM Monitor
  ```
  ```
  [[inputs.swap]]
  ## SWAP Use Monitor
  ```
  ```
  [[inputs.system]]
  ## Uptime Monitor
  ```
  ```
  [[inputs.net]]
  ## NIC Traffic Monitor
  ```

In order to track your wallet balance, please create an Eterscan account and API token.
Edit `tokens.sh` with your wallet address and your Etherscan API token.

Don't forget to `chmod +x successrate.sh tokens.sh`
