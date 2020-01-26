#! /bin/bash
#
# A StorJ node monitor script for telegraf using [inputs.exec]
# Visualizing StorJ V3 node health with Grafana

# Source: https://github.com/gsxryan/storj_telegraf_mon

# Change with the wallt address you want to track
WALLET_ADDRESS="0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
# Change with your personal Etherscan.io API key
ETHERSCAN_API_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Or override variables with tokens.sh.secrets file (not commited)
if [ -f tokens.sh.secrets ]; then
 source tokens.sh.secrets
fi


# Build a curl command to get the wallet balance
CURL_COMMAND="curl -s 'https://api.etherscan.io/api?module=account&action=tokenbalance&contractaddress=0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac&tag=latest&address=$WALLET_ADDRESS&apikey=$ETHERSCAN_API_KEY'"

# Execute the curl command. The output should give something similar to :
#   {"status":"1","message":"OK","result":"11235363320"}
BALANCE_JSON=$(eval $CURL_COMMAND)

# Etherscan's API answer should contain "OK"
if [[ $BALANCE_JSON == *"\"OK\""* ]]; then
  # Use some dark magic to 
  #  - extract the result field
  #  - get the value 
  #  - remove quotes
  #  - translate from satoshi to float token
  BALANCE=$(echo $BALANCE_JSON | grep -oP '(?<="result":")\d+'|awk '{print ($1 / 100000000)}')
  
  # Fetch current STORJ price. Expected output simiar to:
  #  {"USD":0.1605,"EUR":0.1433}
  STORJ_PRICE=$(curl -s 'https://min-api.cryptocompare.com/data/price?fsym=STORJ&tsyms=USD,EUR')

  # API answer should contain "USD"
  if [[ $STORJ_PRICE == *"\"USD\""* ]]; then
    STOR_PRICE_USD=$(echo $STORJ_PRICE | grep -oP '(?<="USD":)[0-9.]+')	
    STOR_PRICE_EUR=$(echo $STORJ_PRICE | grep -oP '(?<="EUR":)[0-9.]+')
    BALANCE_USD=$(echo -e "$BALANCE\t$STOR_PRICE_USD" | awk '{print $1 * $2}')
    BALANCE_EUR=$(echo -e "$BALANCE\t$STOR_PRICE_EUR" | awk '{print $1 * $2}')
  
    echo "StorJToken,stat=tokens,WalletAddress=\"$WALLET_ADDRESS\" BalanceSTORJ=$BALANCE,BalanceUSD=$BALANCE_USD,BalanceEUR=$BALANCE_EUR $(date +'%s%N')"
    echo "StorJToken,stat=prices STORJPriceUSD=$STOR_PRICE_USD,STORJPriceEUR=$STOR_PRICE_EUR $(date +'%s%N')"
  else
    echo "Error, Cryptocompare API returned: $STORJ_PRICE"
  fi

else
  echo "Error, Etherscan API returned: $BALANCE_JSON"
fi
