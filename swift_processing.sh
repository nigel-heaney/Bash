#!/bin/bash
############################################################################
# Filename:     swift_processing.sh
# Written by:   Nigel Heaney
# Decription:   Read source directories and perform gpg encryption & file
#               renaming to processed.
# Version:      1.0
# Date:         13/3/2012
#
# Copyright (C) Wall Street Systems Serivices Corp. 2011
#
############################################################################

# USER Specific Variables
GPGSERIAL=""
CMMPAYMENTS="/tmp"
CMMREADVICE="$APPHOME/var/export/cmmpreadvice"
OPRUSER=""
ARCHIVEMODE=1
DELAY=5
BASEPATH="./"
BASEPATH="."
PNAME="prod_swift"
LOG_FILE=$BASEPATH/$PNAME.log
JOBPID=$BASEPATH/$PNAME.pid

# generic variables
EMAIL="a@d.local"

### General
logentry() {
echo -e "`date`: $1" >> $LOG_FILE
}

mailalert() {
uuencode $LOG_FILE $LOG_FILE | mail -s"`hostname` - $1" $EMAIL
}

start() {
	if [ -s $JOBPID ]; then 
		TPID=`cat $JOBPID`
		echo -e "$PNAME Already Running `cat $JOBPID`\n\t"
		ps -p $TPID 
		exit 1
	fi
	echo $$ > $JOBPID
	logentry "Start command issued..."
	while [ 1 ]; do 
		PSTART=`date +%s`
		processfile
		PTIME=$(( `date +%s` - $PSTART ))
		if [ $PTIME -le $DELAY ]; then
			sleep $(( $DELAY - $PTIME ))
		fi
	done
}

stop() {
	if [ -s $JOBPID ]; then 
		echo "Stopping $PNAME (`cat $JOBPID`)"
		logentry "Stop command issued..."
		TPID=`cat $JOBPID`
		/bin/kill $TPID &> /dev/null
		rm -f $JOBPID
	else
		echo "$PNAME Stopped"
		exit 1
	fi
	
}

status() {
	if [ -s $JOBPID ]; then
		TPID=`cat $JOBPID`
		ps -p $TPID > /dev/null
		if [ $? -eq 0 ]; then 
			echo "$PNAME is Running (`cat $JOBPID`)..."
			exit 1
		else
			echo "Ghost process, performing cleanup...."
			stop
		fi
	else
		echo "$PNAME is Stopped..."
	fi

}

logrotate() {
	#keep 7 revisions of the logs and make it cyclic
	for i in `seq 6 -1 1`; do
		[ -e $LOG_FILE.$i ] && mv -f $LOG_FILE.$i $LOG_FILE.$(($i + 1))
	done 
	[ -e $LOG_FILE ] && { mv -f $LOG_FILE $LOG_FILE.1 ; touch $LOG_FILE; }

}

processfile() {
#check gpg for the key to exist
gpg --list-keys $GPGSERIAL &> /dev/null
if [ $? -gt 0 ]; then
	logentry "ERROR: GPG ($GPGSERIAL) is missing..."
	echo "ERROR: GPG ($GPGSERIAL) is missing..."
	exit 1
fi
if [ $ARCHIVEMODE -eq 1 ]; then
	[ ! -e $CMMPAYMENTS/Archive ] && mkdir -p $CMMPAYMENTS/Archive
	[ ! -e $CMMREADVICE/Archive ] && mkdir -p $CMMREADVICE/Archive
fi

#for loop to process in: *.txt out *.csv.gpg
for i in `ls -1 $CMMPAYMENTS/*.txt 2> /dev/null`; do 
	logentry "Processing $i..."
	fname=`basename $i .txt`.csv
	cp -f $i $CMMPAYMENTS/$fname
	gpg --recipient $GPGSERIAL --encrypt $CMMPAYMENTS/$fname
	#cleanup
	rm -f $CMMPAYMENTS/$fname
	if [ $ARCHIVEMODE -eq 1 ]; then 
		mv $i $CMMPAYMENTS/Archive
		logentry "\tArchiving $i..."
	else
		rm -f $i
		logentry "\tRemoving $i..."
	fi
	logentry "Finished processing $i..."
done

#for loop to process in: *.txt out *.csv.gpg
for i in `ls -1 $CMMREADVICE/*.txt 2> /dev/null`; do
    logentry "Processing $i..."
    fname=`basename $i .txt`.csv
    cp -f $i $CMMREADVICE/$fname
    gpg --recipient $GPGSERIAL --encrypt $CMMREADVICE/$fname
    #cleanup
    rm -f $CMMREADVICE/$fname
    if [ $ARCHIVEMODE -eq 1 ]; then
        mv $i $CMMREADVICE/Archive
        logentry "\tArchiving $i..."
    else
        rm -f $i
        logentry "\tRemoving $i..."
    fi
    logentry "Finished processing $i..."
done

}

showusage() {
echo "Usage: `basename $0` {start|stop|status|logrotate}

start 		- start the daemon process
stop  		- stop the process that us running
status 		- show running status
logrotate 	- rotate the logs"
}

#####################################################################################################
### Main

# Am I who?
if [ ! $(id -un) = $OPRUSER ]
then
        echo "Please execute this script as $OPRUSER"
        exit 1
fi

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status
        ;;
  restart)
        stop
        start
        ;;
  logrotate)
        logrotate
        ;;
  *)
        showusage 
		exit 1
		;;
esac

