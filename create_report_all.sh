#!/bin/sh

##################################################################################
##
## create report from archived logs
##
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

#live_logfile_blocked=/opt/adblock/reports/blocked_report.txt
##################################################
#archive_logfile_dnsmasq=/tmp/mnt/sda3/archive/dnsmasq/$(date "+%d-%m-%y")_dnsmasq.log
#archive_logfile_blocked=/tmp/mnt/sda3/archive/blocked/$(date "+%d-%m-%y")_blocked.log
##################################################

##reports_path=/tmp/mnt/sda3/archive/blocked/
reports_path=/tmp/mnt/sda3/archive/blocked/$(date "+%m")
if [ ! -d $reports_path ]; then
  	# Control will enter here if $DIRECTORY doesn't exist.
	mkdir $reports_path
fi

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
## create combined log of all files
###################################################################################
cat $reports_path/*.log > /tmp/mnt/sda3/archive/blocked/all_blocked_report.txt


#rm /tmp/cycle_logs.lck

