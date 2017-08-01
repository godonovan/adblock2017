#!/bin/sh

##################################################################################
##
##   On Administration Tab, enable Cron and add this job to make the script run
##   every 10 mins. You can change the time as you wish:
##      */10 * * * * root /opt/adblock/query_blocked_log.sh
##
##
##   This script is free for use, modification and redistribution as long as
##   appropriate credit is provided.
##
##   THIS SCRIPT IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT WITHOUT 
##   ANY WARRANTY. IT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER 
##   EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
##   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS
##   TO THE QUALITY AND PERFORMANCE OF THE SCRIPT IS WITH YOU. SHOULD THE SCRIPT
##   PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR 
##   CORRECTION.
##
##################################################################################
# ORIGIN_FILE=/tmp/var/log/messages

ORIGIN_FILE=/tmp/var/dnsmasq.log
###########################################################
#
blocked_list=/opt/adblock/reports/blocked_list.tmp
outlist=/opt/adblock/reports/blocked_report.tmp

outlist2=/opt/adblock/reports/blocked_report2.tmp
blocked_report=/opt/adblock/reports/blocked_report.txt

##############################################################
# Address to send ads to. This could possibily be removed, but may be useful for debugging purposes?
destinationIP="0.0.0.0"
##############################################################


#########################################################################
# Remove Non Blocked (non 0.0.0.0)
#########################################################################
  # Remove nonblocked entries
  if [ -f $ORIGIN_FILE ]; then
    	#logger "gen_host: Removing white-listed domain entries..."
   	 cat $ORIGIN_FILE > $blocked_list

   	#######################################################################
   	#cat $blocked_list | grep $destinationIP | sort -u | sed '/^$/d'> $outlist
  	#cat $blocked_list | grep $destinationIP | sort -u | sed 's/is 0.0.0.0/ /g' > $outlist
   	#
   	########################################################################
   	## Remove 0.0.0.0
   	#cat $blocked_list | grep $destinationIP | sed 's/is 0.0.0.0/ /g' > $outlist
   	#########################################################################

	cat $blocked_list | grep $destinationIP | sort -u | sed 's/is 0.0.0.0/ /g' | sed 's#/opt/adblock/lists/gen_host.txt##g' > $outlist

  fi
 rm $blocked_list

############################################################################################
# Removing duplicates, use awk in case your build of DD-WRT doesn't have sort
############################################################################################
#logger "gen_host: Removing duplicate entries..."
awk '!_[$0]++' $outlist > $blocked_report
##sort -u $outlist >> $blocked_report
##sort -u $outlist >> $blocked_report


#logger "Block List Report updated ..." $blocked_report
logger "query_blocked: Added `wc -l < $outlist` Entries"
rm $outlist

############################################################################################
## Restart DNSMASQ
############################################################################################
#stopservice dnsmasq
#startservice dnsmasq
###########################################################################################