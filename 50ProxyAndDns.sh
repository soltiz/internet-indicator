#!/bin/bash
interface=$1
status=$2

# put me in /etc/NetworkManager/dispatcher.d/

export DISPLAY=:0
export XAUTHORITY=/home/cedric/.Xauthority
export LOGFILE=/tmp/networkManager.log


function log () {
	echo "$@" >> ${LOGFILE}
}


function fatal () {
	log "FATAL ERROR - $@"
	notify-send -u CRITICAL "$@"
	exit 1
}

log ""
log "----------------------------------------"
log "$(date) $interface : $status" 


function getAddr() {
	local interface=$1
	local addr=$(ip -br -f inet a show dev "$interface"  |  sed 's/.* \([0-9]*.*\)\/.*/\1/g')
	if [ "$addr" != "" ]; then
		log "$interface has address : $addr"
	fi
	echo "$addr"
}

log "$0 was called with parameters : $*"

wifiAddr=$(getAddr wlp2s0)
ethAddr=$(getAddr enp0s31f6)
vboxAddr=$(getAddr vboxnet0)
usbAddr=$(getAddr enp0s20f0u5)
dns=""
netw=""
lookuptest=www.google.com
if [[ "$usbAddr" == 192.168.* ]]  ; then
	# HOME or Mobility
	dns=8.8.8.8
	netw=4G
	proxy=""

elif  [ "$ethAddr" == "172.26.45.87" ] ; then
	# SOC
	dns=172.26.30.3
	netw="SOC network"
	proxy=172.26.30.15
elif [ "$wifiAddr" != "" ] ;  then
	# HOME or Mobility
	dns=8.8.8.8
	netw=Roaming
	proxy=""

elif  [ "$ethAddr" == "172.23.4.49" ] ; then
	# IVQ
	dns=172.23.0.194
	netw="IVQ network"
	proxy=172.23.0.6


elif  [[ "$ethAddr" == 20.20.* ]] ; then
	# Punch BOX
	dns=20.20.0.1
	netw="Punch Box"
	proxy=""
	lookuptest="lmcsocasb01i"

fi


log "Target environment: $netw"
if [ -z "$netw" ] ; then
	log "DISCONNECTED"
	notify-send "DISCONNECTED"
	exit 0
fi

log ""
log "   Starting configuration for $netw"
log "---------------------------------------"


ip r del 192.168.56.1 dev enp0s31f6 >& /dev/null
if grep -q vboxnet0 <(ip l show) ; then
	ip a add 192.168.56.1 dev vboxnet0 >& /dev/null
else
	ip a add 192.168.56.1 dev enp0s31f6 >& /dev/null
fi

killall dnsmasq 2> /dev/null
log "installing dnsmasq..."
log dnsmasq --hostsdir /home/cedric/.hosts --max-cache-ttl=10 --server $dns
sleep 1
dnsmasq --hostsdir /home/cedric/.hosts --max-cache-ttl=10 --server $dns >> ${LOGFILE} 2>&1
resolvconf -a aaa <<< "nameserver 192.168.56.1"
resolvconf -u



log -n "DNS check ($dns) : "
if nslookup -timeout=2 $lookuptest > /dev/null ; then
	log "OK"
else
 	log "DNS KO"
fi

sed -i '/^\(cache_peer\|never_direct\)/s/^/#/g' /etc/squid/squid.conf # mise en commentaire de tous les peers et clause "never direct"

if ! [ -z "$proxy" ] ; then
	sed -i '/^#\(cache_peer '$proxy'\|never_direct\)/s/^#//g' /etc/squid/squid.conf # reactivation du peer ic
fi


log "reloading proxy..."
service squid reload ; sleep 2

#log -n "HTTPS check : "
#{ curl -s -S  -m 5 https://www.google.com > /dev/null || curl -s -S -m 4 https://www.google.com > /dev/null  || curl -s -S -m 4 https://www.google.com > /dev/null ; } || fatal "HTTPS CHECK KO"

log "$netw OK "
notify-send	"Configured for $netw !"

