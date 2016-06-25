#!/bin/sh

speed_test(){
file='/tmp/.fastapple'
for ip_addr in $1
do
ping -s 1000 -c 2 $ip_addr |awk '/statistics/{getline a;split(a,b,"[ %]");getline c;split(c,d,"/");if(b[7]==0){print $2","d[4] * 1000}}' >>$file &
done
printf "Compare the running time of CDN with [$2]"
while [ `ps |grep ping |grep -v "grep" |wc -l` -ge 1 ]
do
printf "."
sleep 1
done
printf "\n"
avg_addr_times=`cat $file`
compare=10000000
for avg_addr_time in $avg_addr_times
do
fileaddr=`echo $avg_addr_time |awk -F ',' '{print $1}'`
avgtime=`echo $avg_addr_time |awk -F ',' '{print $2}'`
if [ $avgtime -le $compare ];then
  ip_addr_sel=$fileaddr
  compare=$avgtime
fi
done
for domain in $2
do
if [ "$domain" != "itunes.apple.com" -a "$ip_addr_sel" != "" ];then
echo "address=/$domain/$ip_addr_sel" >>/jffs/configs/apple.conf
fi
done
rm -rf $file
ip_addr_sel=""
}
#main

wan_ipaddr=`ifconfig ppp0 |awk -F'[: ]' '/inet/{print $14}'`
case `curl -s ip.cn?ip=$wan_ipaddr |awk '/^IP/{print $NF}'` in
"电信")
urls='https://raw.githubusercontent.com/gongjianhui/AppleDNS/master/ChinaNet.json'
;;
"移动")
urls='https://raw.githubusercontent.com/gongjianhui/AppleDNS/master/CMCC.json'
;;
"联通")
urls='https://raw.githubusercontent.com/gongjianhui/AppleDNS/master/ChinaUnicom.json'
;;
*)
echo "No CDN json file,exitting..."
exit 1
;;
esac
echo "Downloading $urls..."
wget --no-check-certificate -q $urls -O cdn.json
#wget --no-check-certificate https://raw.githubusercontent.com/gongjianhui/AppleDNS/master/ChinaNet.json -O cdn.json
#if [ ! -d '/jffs/configs/dnsmasq.d' ];then
#mkdir -p /jffs/configs/dnsmasq.d
#fi
for i in 3 7 11 15 19
do
eval dm='\$'$i''
eval ia='\$'$((i+2))''
domains=`awk '{printf $0}' cdn.json |awk -F'[][]' '{print '$dm'}' |sed 's/\"//g;s/ //g;s/,/ /g'`
ip_addrs=`awk '{printf $0}' cdn.json |awk -F'[][]' '{print '$ia'}' |sed 's/\"//g;s/ //g;s/,/ /g;s/\:443//g'`
speed_test "$ip_addrs" "$domains"
done
cat /jffs/configs/apple.conf
rm -rf cdn.json
if [ `grep "conf-file=/jffs/configs/apple.conf" /jffs/configs/dnsmasq.conf.add |wc -l` -lt 1 ];then
echo "conf-file=/jffs/configs/apple.conf" >>/jffs/configs/dnsmasq.conf.add
fi
service restart_dnsmas
logger "fasterapple start!enjoy it.."
echo "OK!enjoy it!!!"
