#!/bin/bash

############################################################################
# Filename:     mb_watch.sh
# Written by:   Nigel Heaney
# Decription:   Script to dump all stats for an AMQ instance
#
# Version:      0.1
# Date:         26/10/12
#
# Copyright (C) Wall Street Systems Serivices Corp. 2011
#
############################################################################

#globals
MBUSER=dbpu
MBPASSWD=ChangeMe

LOGDIR=$WSS_HOME/var/logs/mb_watch             

#main
DATENOW=`date -I`
#create the directory for today
[ ! -e ${LOGDIR}/${DATENOW} ] && mkdir -p ${LOGDIR}/${DATENOW}
LOGFILE=${LOGDIR}/${DATENOW}/`date +%j-%H%M`-mb_watch.log

#check to make sure app is customised, email if not :)
if [ $MBPASSWD == ChangeMe ]; then
	echo "ERROR: mb-watch not configured...Cannot continue" >> $LOGFILE
	echo "ERROR: mb-wtach not configured...Cannot continue" | mail -s "MB-WATCH - configuration error" wmsimp@wallstreetsystems.com
	exit 255
fi

#source the environment
if [ ! -e ~/fkinstall/env.sh ]; then
	echo "ERROR: No source environment script found...Cannot continue" >> $LOGFILE
	exit 255
else
	. ~/fkinstall/env.sh
fi

echo "Extracting AMQ data..."
MBFILE=${LOGDIR}/${DATENOW}/`date +%j-%H%M`-mb_watch.html
date >> $LOGFILE
mb-status -u $MBUSER -p $MBPASSWD -a -y -w $MBFILE
gzip -9 $MBFILE
date >> $LOGFILE

#house keeping - we will compress all directories older than 1 month and then delete zip files older than 3 months
find $LOGDIR -maxdepth 1 -name '20*' -type d -mtime +33 -exec zip -9r {}.zip {} \; -exec /bin/rm -fR {} \;
find $LOGDIR -maxdepth 1 -name '*.zip' -type f -mtime +64 -exec /bin/rm -f {} \;




#!/bin/bash
#simple tool to capture mb-status


