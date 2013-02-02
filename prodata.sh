#!/bin/bash

. testinclude.sh

###################################
# Server
i=10000
  cd ${DATAROOT}/${i}

  grep fail ${DATAROOT}/${i}/logfile.${i}.log
  grep fail ${DATAROOT}/${i}/barnyard2.log

  # Recieve not thread safe...
  #do_store_global_alert=`grep do_store_global_alert ${DATAROOT}/${i}/logfile.${i}.log | wc -l`
  #echo $do_store_global_alert

  # Send
  # shareBlacklist
  #shareBlacklist=`grep shareBlacklist ${DATAROOT}/${i}/logfile.${i}.log | wc -l`
  #echo $shareBlacklist

  # shareBlacklistRecord
  shareBlacklistRecord=`grep shareBlacklistRecord ${DATAROOT}/${i}/logfile.${i}.log | wc -l`
  #echo $shareBlacklistRecord

  # getDomainNodeList
  getDomainNodeList=`grep getDomainNodeList ${DATAROOT}/${i}/logfile.${i}.log | wc -l`
  #echo $getDomainNodeList

  #total=$(($do_store_global_alert+$shareBlacklist+$shareBlacklistRecord+$getDomainNodeList))
  #total=$(($do_store_global_alert+$shareBlacklistRecord+$getDomainNodeList))
  total=$(($shareBlacklistRecord+$getDomainNodeList))

  #echo $total $do_store_global_alert $shareBlacklist $shareBlacklistRecord $getDomainNodeList
  #echo $total $shareBlacklistRecord $getDomainNodeList

###################################
# Client
blacklistHitTotal=0
blacklistNotHitTotal=0
store_global_alertTotal=0
for i in $(seq 10000 $NODEMAX)
do
  cd ${DATAROOT}/${i}

  grep fail ${DATAROOT}/${i}/logfile.${i}.log
  grep fail ${DATAROOT}/${i}/barnyard2.log

  #grep do_store_global_alert ${DATAROOT}/${i}/logfile.${i}.log
  store_global_alert=`grep store_global_alert ${DATAROOT}/${i}/logfile.${i}.log | wc -l`
  store_global_alertTotal=$(($store_global_alertTotal+$store_global_alert))

  # blacklistHit
  blacklistHit=`grep blacklistHit ${DATAROOT}/${i}/logfile.${i}.log | wc -l`
  blacklistHitTotal=$(($blacklistHitTotal+$blacklistHit))
  blacklistNotHit=`grep blacklistNotHit ${DATAROOT}/${i}/logfile.${i}.log | wc -l`
  blacklistNotHitTotal=$(($blacklistNotHitTotal+$blacklistNotHit))

done
echo "store_global_alertTotal ${store_global_alertTotal}"
echo "blacklistHitTotal ${blacklistHitTotal}"
echo "blacklistNotHitTotal ${blacklistNotHitTotal}"

total=$(($total+$store_global_alertTotal))
echo $total $shareBlacklistRecord $store_global_alertTotal $getDomainNodeList
