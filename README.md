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

  [[inputs.exec]]
    commands = ["/path/to/scripts/tokens.sh" ] #some configs may need "sh " before /
    timeout = "60s"
    interval = "1h" # if you don't care to track STORJ price, you can increase it to 24h
    data_format = "influx"
```

In order to track your wallet balance, please create an Eterscan account and API token.
Edit `tokens.sh` with your wallet address and your Etherscan API token.

Don't forget to `chmod +x successrate.sh tokens.sh`
