#!/bin/bash

#fill these in
email="mail@email.com"
key="4234234FAKE593534FAKE6d"
zone="example.com"
record="sub.example.com"
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

ipaddr=$(dig @resolver1.opendns.com ANY myip.opendns.com +short)
cfarec=$(dig $record +short)

if [ "$force" != 1 ]; then
	if [ $ipaddr == $cfarec ]; then 
		echo "IP $ipaddr unchanged"
		updateid=0
	else
		updateip=1
	fi
else
	echo "forcing IP update to: $ipaddr"
	updateip=1
fi

if [ "$updateip" == 1 ]; then
	zidreq=$(curl -sS "https://api.cloudflare.com/client/v4/zones?name=$zone" \
		-H "X-Auth-Email: $email" \
		-H "X-Auth-Key: $key" \
		-H "Content-Type: application/json")
	zid=$(echo $zidreq | grep -Po '(?<="id":")[^"]*' | head -1)

	ridreq=$(curl -sS "https://api.cloudflare.com/client/v4/zones/$zid/dns_records?name=$record" \
		-H "X-Auth-Email: $email" \
		-H "X-Auth-Key: $key" \
		-H "Content-Type: application/json") 
	rid=$(echo $ridreq | grep -Po '(?<="id":")[^"]*')

	update=$(curl -sSX PUT "https://api.cloudflare.com/client/v4/zones/$zid/dns_records/$rid" \
     	-H "X-Auth-Email: $email" \
     	-H "X-Auth-Key: $key" \
     	-H "Content-Type: application/json" \
     	--data '{"type":"A","name":"'${record}'","content":"'${ipaddr}'","ttl":1,"proxied":false}')
fi

if [ "$log" == 1 ]; then
	printf "Current IP for $record is: $cfarec\n" | tee -a ~/log-cfddns
	printf "Current public IP is: $ipaddr\n\n" | tee -a ~/log-cfddns
	if [ "$updateip" == 1 ]; then 
		printf "$zidreq\n\n" >> ~/log-cfddns
		printf "$ridreq\n\n" >> ~/log-cfddns
		printf "$update" | tee -a ~/log-cfddns
	else
		printf "IP has not changed, no requests made to cloudflare\n\n" >> ~/log-cfddns
	fi
	printf "\n\nSee file: ~/log-cfddns for details\n\n" 
	exit 0
fi

printf "$update"
exit 0
