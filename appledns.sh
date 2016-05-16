#!/bin/sh
if [ ! -d "/jffs/configs/dnsmasq.d" ];then
mkdir -p /jffs/configs/dnsmasq.d/
fi
wget --no-check-certificate https://raw.githubusercontent.com/gongjianhui/AppleDNS/master/ChinaNet.json -O chinanet.json
avgcompare(){
  for ip_addr in $*
  do
  wget -t1 -T 2 -o http.log -O html1 $ip_addr
  if [ `cat http.log |grep "connected" |wc -l` -gt 0 ];then
  eval ip_addr=`echo $ip_addr |sed 's/\:443//'`
  ping_result=`ping -s 1000 -c 2 $ip_addr |awk '/loss/{split($7,a,"%");getline b;split(b,c,"/");print a[1]" "c[4]}'`
  avgtime=`echo $ping_result |awk '{print $2 * 1000}'`
  lossnum=`echo $ping_result|awk '{print $1}'`
  echo "$ip_addr  $avgtime"
  if [ "$avgtime" != "" -a $lossnum -eq 0 ];then
  if [ $avgtime -le $compare ];then
  ip_addr_sel=$ip_addr
  compare=$avgtime
  fi
  fi
  fi
  done
  echo $ip_addr_sel
}
dnsmasq(){
for domain in $*
do
if [ "$domain" != "itunes.apple.com" -a "$ip_addr_sel" != "" ];then
echo "address=/$domain/$ip_addr_sel" >>/jffs/configs/dnsmasq.d/apple.conf
fi
done
$ip_addr_sel="" 
}
for i in 3 7 11 15 19
do
eval dm='\$'$i''
eval ia='\$'$((i+2))''
domains=`awk '{printf $0}' chinanet.json |awk -F'[][]' '{print '$dm'}' |sed 's/\"//g;s/ //g;s/,/ /g'`
ip_addrs=`awk '{printf $0}' chinanet.json |awk -F'[][]' '{print '$ia'}' |sed 's/\"//g;s/ //g;s/,/ /g'`
compare=10000000
avgcompare $ip_addrs
dnsmasq $domains
done
cat /jffs/configs/dnsmasq.d/apple.conf
rm -rf chinanet.json 
wget --no-check-certificate -qO - https://raw.githubusercontent.com/FasterApple/fasterapple/master/db/appstore | awk '/^a/{print "address=/phobos.apple.com/"$4 }' |awk '!a[$0]++' >>/jffs/configs/dnsmasq.d/apple.conf
[ `grep "conf-dir=/jffs/configs/dnsmasq.d" /jffs/configs/dnsmasq.conf.add |wc -l` -eq 0 ] && echo "conf-dir=/jffs/configs/dnsmasq.d" >>/jffs/configs/dnsmasq.conf.add
service restart_dnsmasq
