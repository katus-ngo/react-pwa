#!/bin/bash

ip=`hostname -I | cut -f1 -d' '`
target_ip=`avahi-resolve -4 -n ${nodeco} | cut -f2`

for i in {1..32}; do
	if [ $i -eq 1 ]; then
		nodeco="nodeco.local"
	else
		nodeco="nodeco-${i}.local"
	fi

	target_ip=`avahi-resolve -4 -n ${nodeco} | cut -f2`
	if [ "${ip}" == "${target_ip}" ]; then
		echo "Making cert files: DNS.1=${nodeco} IP.1=${ip}"
		rm -rf nodeco
		./make_cert.sh -n nodeco -p Spenge -d 73000 -c JP -s Japan -l Tokyo -o Spenge_Co_Ltd -u Spenge -a DNS.1=${nodeco} -a IP.1=${ip}
		mkdir -p /mnt/sd/nodeco-api/ssl
		cp nodeco/server.key /mnt/sd/nodeco-api/ssl/server.key
		cp nodeco/server.crt /mnt/sd/nodeco-api/ssl/server.crt
		cp nodeco/cacert.crt /mnt/sd/nodeco-api/ssl/cacert.crt
		chown stakers:stakers /mnt/sd/nodeco-api/ssl/server.key
		chown stakers:stakers /mnt/sd/nodeco-api/ssl/server.crt
		chown stakers:stakers /mnt/sd/nodeco-api/ssl/cacert.crt
		break;
	fi
done
