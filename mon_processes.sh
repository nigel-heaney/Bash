#!/bin/bash

############################################################################
# Filename:     mon_processes.sh
# Written by:   Nigel Heaney
# Decription:   Monitor all current processes and sort by memo usage
#
# Version:      0.1
# Date:         26/10/12
#
############################################################################

#globals
LOGDIR=$APPHOME/var/logs/mon/mon_processes                   
[ -e $LOGDIR ] && mkdir -p $LOGDIR

#main
echo "Checking Memory usage per processes..."
DATENOW=`date -I`
#create the directory for today
[ ! -e ${LOGDIR}/${DATENOW} ] && mkdir -p ${LOGDIR}/${DATENOW}

#MEM Usage
LOGFILE=${LOGDIR}/${DATENOW}/`date +%j-%H%M`-mon_processes.log
date > $LOGFILE
#grab the stats and sort by mem
ps -eo %mem,%cpu,vsz,cputime,pid,comm,args | sort -rk 1 >> $LOGFILE
date >> $LOGFILE

# CPU top -b -n 1 | head -n 6
LOGFILE=${LOGDIR}/${DATENOW}/`date +%j-%H%M`-mon_processes_top.log
date > $LOGFILE
#grab the stats and sort by mem
top -b -n 1i | head -n 6 >> $LOGFILE
mpstat -P ALL >> $LOGFILE
date >> $LOGFILE

#house keeping - we will compress all directories older than 1 day and then delete zip files older than 1 month
find $LOGDIR -maxdepth 1 -name '20*' -type d -mtime +1 -exec zip -9r {}.zip {} \; -exec /bin/rm -fR {} \;
find $LOGDIR -maxdepth 1 -name '*.zip' -type f -mtime +30 -exec /bin/rm -f {} \;

