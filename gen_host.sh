#!/bin/sh

##################################################################################
##
## gen_hosts by IronManLok
## https://gist.github.com/kenci/3fbc06853069408cb28a330c2a3719b3
##
##   Downloads domain entries of known ad abusers from multiple sources, 
##   cleans up, merges and removes duplicates. Includes white-listing and
##   custom host entries.
##   
##
## This script is intended to be used on units running DD-WRT kongac with kernel
##   4.4+ it requires the use of opt (or USB drive mounted on /opt) and DNSMasq as DNS server.
##
##   Also, you should be using DNSMasq as DNS server, and OPKG package manager
##   (required packages: ca_certificates, ipset, iptables).
##
##      1) Run "bootstrap".
##      2) Check by running "opkg --version".
##      3) Run "opkg update".
##      4) Run "opkg install ca-certificates".
##      5) Run "opkg install iptables".
##      6) Run "opkg install ipset".
##
##   On Services Tab, at Additional DNSMasq options, add this line:
##      addn-hosts=/tmp/gen_host.txt
##
##   On Administration Tab, enable Cron and add this job to make the script run
##   daily at 22:00. You can change the time as you wish:
##      0 22 * * * root /opt/adblock/gen_host.sh
##
##
##   For white-listing, create /opt/adblock/lists/whitelist_hosts.txt and list one domain
##   per line. For custom hosts entries, create /opt/adblock/lists/my_hosts.txt and 
##   add any lines in the same format of a regular hosts file.
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

wait_for_connection() {
  while :; do
    ping -c 1 -w 10 www.google.com > /dev/null 2>&1 && break
    sleep 60
    logger "gen_host: Retrying internet connection..."
    done
}
#
CA_PATH=/opt/etc/ssl/certs
LIVE_FILE=/opt/adblock/lists/gen_host.txt
ORIGIN_FILE=/opt/adblock/lists/gen_host.tmp
whitelist=/opt/adblock/lists/whitelist_hosts.txt
myblocklist1=/opt/adblock/lists/my_blocked_hosts.txt
tmpwhitelist=/opt/adblock/lists/gen_host-whitelist.tmp

###################################################################################
##
###################################################################################
download_file()
{
  ATTEMPT=1
  OUTPUT_FILE="$2"
  HTTP_CODE="$2.http"

  while :; do
    if [ -f "$OUTPUT_FILE" ]; then
      rm "$OUTPUT_FILE"
    fi

    if [ -f "$HTTP_CODE" ]; then
      rm "$HTTP_CODE"
    fi

    # Skip URL after 3 failed attempts...
    if [ $ATTEMPT = 4 ]; then
      logger "gen_host: Skipping $1 ..."
      return 1
    fi

    logger "gen_host: Downloading $1 (attempt `echo $ATTEMPT`)..."
    (curl -o "$OUTPUT_FILE" --silent --write-out '%{http_code}' --connect-timeout 90 --max-time 150 --capath $CA_PATH -L "$1" > "$HTTP_CODE") & DOWNLOAD_PID=$!

    wait $DOWNLOAD_PID
    RESULT=$?
    HTTP_RESULT=`cat "$HTTP_CODE"`
    rm "$HTTP_CODE"

    if [ $RESULT = 0 ] && [ $HTTP_RESULT = 200 ]; then
      logger "gen_host: Download succeeded [ $URL ]..."
      return 0
    else
      logger "gen_host: Download failed [ $HTTP_RESULT $RESULT ]..."
      ATTEMPT=$(($ATTEMPT + 1))
      sleep 10
    fi
  done
}
#######################################################################################

CURRENT_TIME=$(date +%s)

# Time hasn't been set yet
if [ $CURRENT_TIME -lt 3600 ]; then
  logger "gen_host: Ran before NTP, quiting."
  exit 1
fi

############################################################################################
# Check if the script ran less than 6 hours ago, to avoid spamming downloads
############################################################################################
#if [ -f /opt/adblock/lists/gen_host.lastdl ] && [ -f /opt/adblock/lists/gen_host.txt ] && [ -f /opt/adblock/lists/gen_ip.txt ] &&
#   [ $(($CURRENT_TIME - $(cat /opt/adblock/lists/gen_host.lastdl))) -lt 21600 ]; then
#  logger "gen_host: Last download ran less than 6 hours ago, quiting."
#  exit 1
#fi

#############################################################################################

##################################################################################
# Makes sure only one instance of this script is running
##################################################################################
if test -s /opt/adblock/lists/gen_host.lck; then
  logger "gen_host: Already running, quitting."
  exit 1
fi
echo $$ > /opt/adblock/lists/gen_host.lck
sleep 1

###################################################################################
# Check for race conditions, when 2 instances start at the same time
###################################################################################
if [ "$(cat /opt/adblock/lists/gen_host.lck)" != "$$" ]; then
  logger "gen_host: Race condition, quiting."
  exit 1
fi

##################################################################################

logger "gen_host: Generating hosts file..."

logger "gen_host: Started..."

echo "">/opt/adblock/lists/gen_host.tmp
echo "">/opt/adblock/lists/gen_ip.tmp

wait_for_connection

COUNT=1
ANY_HOST_DOWNLOAD=0
ANY_IP_DOWNLOAD=0

# The script must run within 1200 seconds, this will create a timer to terminate it
(sleep 1200 && logger "gen_host: Execution timed out." && rm /opt/adblock/lists/gen_host_upd.tmp && kill -TERM $$) & TIMEOUT_PID=$!

##########################################################
logger "gen_host: Downloading DOMAIN lists..."
#
#	   
#          "https://github.com/lewisje/jansal/tree/master/adblock/hosts" \
#          "http://adblock.gjtech.net/?format=hostfile" \
#
for URL in "http://winhelp2002.mvps.org/hosts.txt" \
	   "https://raw.githubusercontent.com/lewisje/jansal/master/adblock/hosts" \
           "http://someonewhocares.org/hosts/zero/hosts" \
           "http://www.malwaredomainlist.com/hostslist/hosts.txt" \
           "http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&mimetype=plaintext" \
           "http://hosts-file.net/ad_servers.txt" \
           "http://mirror1.malwaredomains.com/files/BOOT" \
           "http://malc0de.com/bl/BOOT" \
           "http://hosts-file.net/ad_servers.txt" \
           "https://zeustracker.abuse.ch/blocklist.php?download=hostfile" \
           "http://www.hostsfile.org/Downloads/hosts.txt"; do

   

##########################################
##Start file download
#########################################
# Each file should be downloaded within 120 seconds
TEMP_FILE="/opt/adblock/lists/gen_host`echo $COUNT`.tmp"
download_file $URL $TEMP_FILE

###################################################################################
    # Clean-up:
    #  1) removes CR
    #  2) converts double spaces/tabs to single tab
    #  3) removes leading spaces
    #  4) removes trailing spaces
    #  5) removes empty lines
    #  6) removes fully commented lines
    #  7) removes trailing comments
    #  8) removes invalid characters
    #  9) replaces 127.0.0.1 with 0.0.0.0
    # 10) removes non-leading 127.0.0.1 or 0.0.0.0
    # 11) keeps only valid 0.0.0.0 entries
    # 12) removes any lines with localhost
    # 13) breaks up multiple entries on a single line into several single entry lines

    if [ $RESULT = 0 ]; then
      cat "$TEMP_FILE" | tr -d '\015' | \
                         sed -r -e 's/[[:space:]]+/\t/g' \
                                -e 's/^\t//g' \
                                -e 's/\t$//g' \
                                -e '/^$/d' \
                                -e '/^#/d' \
                                -e 's/\t*#.*$//g' \
                                -e 's/[^a-zA-Z0-9\.\_\t\-]//g' \
                                -e 's/^127\.0\.0\.1/0.0.0.0/g' \
                                -e 's/\t(0\.0\.0\.0|127\.0\.0\.1)//g' | \
                         grep ^0'\.'0'\.'0'\.'0$'\t'. | \
                         grep -v -F localhost | \
                         sed -e 's/^0\.0\.0\.0\t/0.0.0.0%/1' -e 's/\t/%%0\.0\.0\.0\t/g' -e 's/^0\.0\.0\.0%/0.0.0.0\t/1' -e 's/%%/\n/g' \
                         >> /opt/adblock/lists/gen_host.tmp
      rm "$TEMP_FILE"
      ANY_HOST_DOWNLOAD=1
      #break
    fi

COUNT=$(($COUNT + 1))
done
    
#########################################################################
##
#########################################################################
logger "gen_host: Downloading IP lists..."

for URL in "https://raw.githubusercontent.com/ktsaou/blocklist-ipsets/master/firehol_level1.netset" \
           "https://zeustracker.abuse.ch/blocklist.php?download=ipblocklist" \
           "http://malc0de.com/bl/IP_Blacklist.txt" \
           "http://www.team-cymru.org/Services/Bogons/fullbogons-ipv4.txt"; do
  TEMP_FILE="/tmp/gen_ip`echo $COUNT`.tmp"
  download_file $URL $TEMP_FILE
  if [ $? = 0 ]; then
    cat "$TEMP_FILE" | tr -d '\015' | \
                       sed -r -e 's/[[:space:]]+/\t/g' \
                              -e 's/^\t//g' \
                              -e 's/\t$//g' \
                              -e '/^$/d' \
                              -e '/^#/d' \
                              -e 's/\t*(#|\/\/).*$//g' \
                              -e 's/[^0-9\.\/]//g' \
                       >> /opt/adblock/lists/gen_ip.tmp
    rm "$TEMP_FILE"
    ANY_IP_DOWNLOAD=1
  fi

  COUNT=$(($COUNT + 1))
done

##########################################################################################################
##########################################################################################################

########################
# If no file were downloaded at all, retry after 60 minutes...
########################
#if [ $ANY_IP_DOWNLOAD = 0 ] && [ $ANY_HOST_DOWNLOAD = 0 ]; then
#  logger "gen_host: No file downloaded, retrying after 60 minutes..."
#  (sleep 3600 && /opt/adblock/lists/gen_host.sh) &
#  rm /opt/adblock/lists/gen_host.lck
#  kill -KILL $TIMEOUT_PID
#  exit 2
#fi

date +%s>/opt/adblock/lists/gen_host.lastdl
logger "gen_host: Downloaded `wc -l < /opt/adblock/lists/gen_host.tmp` DOMAIN and `wc -l < /opt/adblock/lists/gen_ip.tmp` IP entries..."

#########################################################################
# Add custom host entries to the file (/opt/adblock/lists/my_blocked_hosts.txt)
#########################################################################
if test -s $myblocklist1; then
  logger "gen_host: Adding custom host entries..."
  cat $myblocklist1 >> $ORIGIN_FILE
  logger "gen_host: Adding `wc -l < $myblocklist1` extra sites from Custom blocklist1..."
fi

#########################################################################
# Remove white-listed entries
#########################################################################
if test -s /opt/adblock/lists/whitelist_hosts.txt; then
  logger "gen_host: Removing white-listed entries..."

  ORIGIN_FILE="/opt/adblock/lists/gen_host.tmp"

  cat $ORIGIN_FILE | sed $'s/\r$//' |grep -F -v -f $whitelist > $tmpwhitelist
  cat $tmpwhitelist > /opt/adblock/lists/gen_host.tmp
fi
rm $tmpwhitelist

############################################################################################
# Removing duplicates, use awk in case your build of DD-WRT doesn't have sort
############################################################################################
#logger "gen_host: Removing duplicate entries..."
awk '!x[$0]++' /opt/adblock/lists/gen_host.tmp > /opt/adblock/lists/gen_host.txt
## sort -u /opt/adblock/lists/gen_host.tmp > /opt/adblock/lists/gen_host.txt
## sort -u /opt/adblock/lists/gen_host.tmp > /opt/adblock/lists/gen_host.txt
rm /opt/adblock/lists/gen_host.tmp

############################################################################################
## Restart DNSMASQ
############################################################################################
logger "gen_host: Generated `wc -l < /opt/adblock/lists/gen_host.txt` domain entries. Restarting DNSMasq..."

stopservice dnsmasq
startservice dnsmasq
###########################################################################################

###########################################################################################
## Removing duplicate IP
###########################################################################################
if [ $ANY_IP_DOWNLOAD != 0 ]; then
  # Removing duplicates
  logger "gen_host: Removing duplicate IP entries..."
  sort -u /opt/adblock/lists/gen_ip.tmp | sed -r -e '/^$/d' > /opt/adblock/lists/gen_ip.txt
  rm /opt/adblock/lists/gen_ip.tmp

  logger "gen_host: Generated `wc -l < /opt/adblock/lists/gen_ip.txt` IP entries. Creating firewall rules..."

  ###### /opt/adblock/ipset_setup.sh
fi


rm /opt/adblock/lists/gen_host.lck
kill -KILL $TIMEOUT_PID
logger "gen_host: Finished."