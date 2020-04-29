#!/bin/bash

#fill these in
email="Your Cloudflare Email"
key="Global Key"
zone="your.domain"
record="example.your.domain"
#

for opt in "$@"; do
  case $opt in
  --log)
    log=1
    ;;
  --force)
    force=1
    ;;
  esac
done

# ipaddr=$(dig @resolver1.opendns.com ANY myip.opendns.com +short)
ipaddr=$(curl -s ipv4.icanhazip.com)
cfarec=$(dig $record +short)
ipipaddr=$(curl -s myip.ipip.net)
time=$(date)

if [ "$force" != 1 ]; then
  if [ $ipaddr == $cfarec ]; then
    echo -e Time:[$(date)] IPAddr:[$ipipaddr] Status:[Unchanged] '\n'
    updateip=0
  else
    updateip=1
  fi
else
  echo "forcing IP update to: $ipaddr"
  updateip=1
fi

if [ "$updateip" == 1 ]; then
  zidreq=$(
    curl -sS "https://api.cloudflare.com/client/v4/zones?name=$zone" \
    -H "X-Auth-Email: $email" \
    -H "X-Auth-Key: $key" \
    -H "Content-Type: application/json"
  )
  zid=$(echo $zidreq | grep -Po '(?<="id":")[^"]*' | head -1)

  ridreq=$(
    curl -sS "https://api.cloudflare.com/client/v4/zones/$zid/dns_records?name=$record" \
    -H "X-Auth-Email: $email" \
    -H "X-Auth-Key: $key" \
    -H "Content-Type: application/json"
  )
  rid=$(echo $ridreq | grep -Po '(?<="id":")[^"]*')

  update=$(
    curl -sSX PUT "https://api.cloudflare.com/client/v4/zones/$zid/dns_records/$rid" \
    -H "X-Auth-Email: $email" \
    -H "X-Auth-Key: $key" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'${record}'","content":"'${ipaddr}'","ttl":1,"proxied":false}'
  )
fi

if [ "$log" == 1 ]; then
  printf "Current Time： $time\n" | tee -a ~/log-cfddns
  printf "Current IP for $record is: $cfarec\n" | tee -a ~/log-cfddns
  printf "Current public IP is: $ipaddr\n\n" | tee -a ~/log-cfddns
  if [ "$updateip" == 1 ]; then
    printf "$zidreq\n\n" >>~/log-cfddns
    printf "$ridreq\n\n" >>~/log-cfddns
    printf "$update" | tee -a ~/log-cfddns
  else
    printf "IP has not changed, no requests made to cloudflare\n\n\n" >>~/log-cfddns
  fi
  exit 0
fi

printf "$update"
exit 0
