#!/bin/bash
set -f
############################################################################
#
# Filename:     pmm_monitor
# Written by:   Nigel Heaney
# Decription:   This script will monitor process monitor server and agent daemons
#               and alert if necessary.
#
# Version       Date            Description
# 1.0           15/10/13        First Draft
#
############################################################################

# source env - 
. ~/fkinstall/env.sh

# Globals
EMAIL="a@d.local"
LOG_FILE=$WSS_HOME/var/logs/mon/pmm_monitor.log
PROCESS_EXCLUDES="grep|tail"
PROCESS_LIST="pmsd pmad"

start_process() {
	if [ -e $WSS_HOME/bin/${1}.sh ]; then
		$PMM_HOME/${1}.sh start > /dev/null 2>&1
	elif [ -e ~/ProcessMonitor/${1}.sh ]; then
		~/ProcessMonitor/${1}.sh start > /dev/null 2>&1
	else
		#fallback
		$PMM_HOME/${1}.sh start > /dev/null 2>&1
	fi
	echo -e "`date +\"date +%F@%H%M\"`: Restarted the ${1} process" >> $LOG_FILE
}

### MAIN ###
#check fk_node_id, if > 0 then slave node so only monitor pmad
[ $FK_NODE_ID -gt 0 ] && PROCESS_LIST="pmad"

for PROCESS in $PROCESS_LIST; do 
	if [ `ps -fu $USER | grep $PROCESS | egrep -v $PROCESS_EXCLUDES | wc -l` = 0 ]
	then
			start_process $PROCESS
			echo -e "$PROCESS has either crashed or been stopped,  Auto-restart has been attempted." | mail -s"WARNING - $PROCESS Crashed/Stopped on `hostname -s`" $EMAIL
	fi
done



