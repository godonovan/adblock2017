#!/bin/sh

##################################################################################
##
## cycle_logs by gordonNet
##
##
## This script is intended to be used on units running DD-WRT kongac with kernel
##   4.4+ it requires the use of opt (or USB drive mounted on /opt) and DNSMasq as DNS server.
##
##
##
##   On Administration Tab, enable Cron and add this job to make the script run
##   daily at 22:00. You can change the time as you wish:
##      0 22 * * * root /opt/adblock/cycle_logs.sh
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

live_logfile_dnsmasq=/tmp/var/dnsmasq.log
live_logfile_blocked=/opt/adblock/reports/blocked_report.txt
##################################################

archive_logfolder_dnsmasq=/tmp/mnt/sda3/archive/dnsmasq/$(date "+%m")
if [ ! -d $archive_logfolder_dnsmasq ]; then
  	# Control will enter here if $DIRECTORY doesn't exist.
	mkdir $archive_logfolder_dnsmasq
fi
archive_logfile_dnsmasq=$archive_logfolder_dnsmasq/$(date "+%d-%m-%y")_dnsmasq.log
###################

archive_logfolder_blocked=/tmp/mnt/sda3/archive/blocked/$(date "+%m")
if [ ! -d $archive_logfolder_blocked ]; then
  	# Control will enter here if $DIRECTORY doesn't exist.
	mkdir $archive_logfolder_blocked
fi
archive_logfile_blocked=$archive_logfolder_blocked/$(date "+%d-%m-%y")_blocked.log
##################


#
##################################################################################
# Makes sure only one instance of this script is running
##################################################################################
#if test -s /tmp/cycle_logs.lck; then
#  logger "cycle_logs: Already running, quitting."
#  exit 1
#fi
#echo $$ > /tmp/cycle_logs.lck
#sleep 1

###################################################################################
## copy log to archive
###################################################################################
cat $live_logfile_dnsmasq >> $archive_logfile_dnsmasq
cat $live_logfile_blocked >> $archive_logfile_blocked

logger "Archive '$archive_logfile_dnsmasq' Created"
logger "Archive '$archive_logfile_blocked' Created"

###################################################################################
## create combined log of all files
###################################################################################
cat $archive_logfolder_blocked/*.log > /tmp/mnt/sda3/archive/blocked/all_blocked_report.txt


###################


###################################################################################
##Erase Log DNSMASQ file (when service restarts new file created)
###################################################################################
rm $live_logfile_dnsmasq

###################################################################################
##Create empty blocked_report.txt (will be updated when update_blocked.sh next runs (every 10 mins)
###################################################################################
echo > $live_logfile_blocked

############################################################################################
## Restart DNSMASQ
############################################################################################
stopservice dnsmasq
startservice dnsmasq
###########################################################################################


#rm /tmp/cycle_logs.lck
