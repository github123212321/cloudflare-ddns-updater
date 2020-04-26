#!/bin/bash

#fill these in
email="mail@email.com"
key="787987FAKE808790807889FAKE"
zone="example.com"
record="sub.example.com"
#


for opt in "$@"; do
	case $opt in 
	--force)
		force=1
		;;
	--debug)
		debug=1
		;;
	esac
done 


ipaddr=$(dig @resolver1.opendns.com ANY myip.opendns.com +short)

if [ "$force" != 1 ]; then
	cfarec=$(dig $record +short)
	if [ $ipaddr == $cfarec ]; then 
		echo "IP $ipaddr unchanged"
		exit 0
	fi
	echo "forcing update anway"
fi

zid=$(curl -sS "https://api.cloudflare.com/client/v4/zones?name=$zone" \
	-H "X-Auth-Email: $email" \
	-H "X-Auth-Key: $key" \
	-H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)

rid=$(curl -sS "https://api.cloudflare.com/client/v4/zones/$zid/dns_records?name=$record" \
	-H "X-Auth-Email: $email" \
	-H "X-Auth-Key: $key" \
	-H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

update=$(curl -sSX PUT "https://api.cloudflare.com/client/v4/zones/$zid/dns_records/$rid" \
     -H "X-Auth-Email: $email" \
     -H "X-Auth-Key: $key" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'${record}'","content":"'${ipaddr}'","ttl":1,"proxied":false}')


if [ "$debug" == 1 ]; then
#debug to be fixed later
	echo $zid
	echo $rid
	echo $update
	exit 0
fi

echo $update
