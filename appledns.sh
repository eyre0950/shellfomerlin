#!/bin/sh
if [ ! -d "/jffs/configs/dnsmasq.d" ];then
mkdir -p /jffs/configs/dnsmasq.d/
fi
wget --no-check-certificate https://raw.githubusercontent.com/gongjianhui/AppleDNS/master/ChinaNet.json -O chinanet.json
avgcompare(){
  for ip_addr in $*
  do
  avgtime=`ping -s 1000 -c 2 $ip_addr |awk -F'/' '/round-trip/ {print $4}'|sed 's/\.//g'`
  echo "$ip_addr  $avgtime"
  if [ "$avgtime" != "" ];then
  if [ $avgtime -le $compare ];then
  ip_addr_sel=$ip_addr
  compare=$avgtime
  fi
  fi
  done
  echo $ip_addr_sel
}
dnsmasq(){
for domain in $*
do
if [ "$domain" != "itunes.apple.com" ];then
echo "address=/$domain/$ip_addr_sel" >>/jffs/configs/dnsmasq.d/apple.conf
fi
done
}
for i in 3 7 11 15 19
do
eval dm='\$'$i''
eval ia='\$'$((i+2))''
domains=`awk '{printf $0}' chinanet.json |awk -F'[][]' '{print '$dm'}' |sed 's/\"//g;s/ //g;s/,/ /g'`
ip_addrs=`awk '{printf $0}' chinanet.json |awk -F'[][]' '{print '$ia'}' |sed 's/\"//g;s/ //g;s/,/ /g;s/\:443//g'`
compare=10000000
avgcompare $ip_addrs
dnsmasq $domains
done
cat /jffs/configs/dnsmasq.d/apple.conf
rm -rf chinanet.json 
wget --no-check-certificate -qO - https://raw.githubusercontent.com/FasterApple/fasterapple/master/db/appstore |awk '{if( /^a/) {print "address=/"$1".phobos.apple.com""/"$4"" }}' >>/jffs/configs/dnsmasq.d/apple.conf
echo "conf-dir=/jffs/configs/dnsmasq.d" >> /jffs/configs/dnsmasq.conf.add
service restart_dnsmasq
