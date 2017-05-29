#!/bin/bash

############################################################################
# Filename:     swift_sftp.sh
# Written by:   Nigel Heaney
# Decription:   Perform file management functions for the SWIFT interfaces
#               
# Version:      1.0
# Date:         17/1/2012
#
############################################################################

# USER Specific Variables
SFTPSERVER="sftp://x.y.z"
SFTPUSER="xxx"
MYENV="xxPROD"
LOCAL_MT101=~/ImportExport/CashManagement/SWIFT/EFT/In
LOCAL_NACK=~/ImportExport/CashManagement/SWIFT/EFT/Out
LOCAL_MT900=~/ImportExport/CashManagement/SWIFT/EFT/Out
LOCAL_MT940=~/ImportExport/CashManagement/SWIFT/ARS/MT940
LOCAL_MT942=~/ImportExport/CashManagement/SWIFT/ARS/MT942
LOCAL_BAIPDR=~/ImportExport/CashManagement/SWIFT/ARS/Forwarded
LOCAL_BAICDR=~/ImportExport/CashManagement/SWIFT/ARS/Forwarded

JOBSTART=`date +%s`
JOBNUM=`date +%j-%k%M`
JOBPID=~/ImportExport/tmp/$MYENV-swift_sftp.pid
JOBCYCLE=~/ImportExport/tmp/$MYENV-swift.properties
LOG_FILE=~/ImportExport/tmp/$MYENV-swift_sftp-$JOBNUM.log
FTP_JOB=~/ImportExport/tmp/$MYENV-swift_sftp.job

# generic variables
EMAIL="a@d.local"

### General
logentry() {
echo -e "`date +\"%T\"`: $1" >> $LOG_FILE
}

mailalert() {
uuencode $LOG_FILE $LOG_FILE | mail -s"$MYENV - $1" $EMAIL
}

process_ftp_job() {
logentry "Executing isftp transfers"
cat /dev/null > ~/.lftp/transfer_log
lftp -f $FTP_JOB
#append transfers to log
cat ~/.lftp/transfer_log >> $LOG_FILE
}

file_maintenance() {
# perform tidy up of aging log files etc.
find ~/ImportExport/tmp -name '$MYENV*.log' -mtime +3 -exec rm -f {} \;

}

### Main
[ -e $JOBPID ] && { log "ERROR: Already running...(`cat $JOBPID`): Aborted"; mailalert "Error previous SWIFT SFTP process still running"; exit 1; }
if [ ! -e $JOBCYCLE ]; then
        CYCLE=1
        echo $CYCLE > $JOBCYCLE
        logentry "No properties file found, starting from beginning"
else
        CYCLE=$((`cat $JOBCYCLE` + 1))
        [ $CYCLE -ge 6 ] && CYCLE=1;
        echo $CYCLE > $JOBCYCLE

fi
#
# check direcories exist
mkdir -p LOCAL_MT101
mkdir -p LOCAL_NACK
mkdir -p LOCAL_MT900
mkdir -p LOCAL_MT940
mkdir -p LOCAL_MT942
mkdir -p LOCAL_BAIPDR
mkdir -p LOCAL_BAICDR
mkdir -p ~/ImportExport/tmp

echo -e  "Start SFTP Transfers with SWIFT...\n\tJob Num: $JOBNUM\n\tCycle Num: $CYCLE\n\tTime:`date`\n" > $LOG_FILE

echo $JOBNUM > $JOBPID
echo "open -u $SFTPUSER,x $SFTPSERVER" > $FTP_JOB
echo -e "lcd $LOCAL_MT101\ncd ~/EFT/In\nmput -cE *" >> $FTP_JOB

case $CYCLE in
        1)      echo "Cycle1 - Processing MT101 and NACKS" >> $LOG_FILE
                echo -e "lcd $LOCAL_NACK\ncd ~/EFT/Out\nmget -cE 7515F01_*_*_confirm.xml.asc" >> $FTP_JOB
                process_ftp_job
        ;;
        2)      echo "Cycle2 - Processing MT101 and MT900" >> $LOG_FILE
                #echo -e "lcd $LOCAL_MT900\ncd ~/ARS/MT900\nmget -cE *" >> $FTP_JOB
                process_ftp_job
        ;;
        3)      echo "Cycle3 - Processing MT101 and MT940" >> $LOG_FILE
                echo -e "lcd $LOCAL_MT940\ncd ~/ARS/MT940\nmget -cE MT940*.*" >> $FTP_JOB
                process_ftp_job
        ;;
        4)      echo "Cycle4 - Processing MT101 and MT942" >> $LOG_FILE
                echo -e "lcd $LOCAL_MT942\ncd ~/ARS/MT942\nmget -cE MT942*.*" >> $FTP_JOB
                process_ftp_job
        ;;
        5)  echo "Cycle5 - Processing MT101, BAIPDR and BAICDR" >> $LOG_FILE
            echo -e "lcd $LOCAL_BAIPDR\ncd ~/ARS/Forwarded\nmget -cE BAI*_PD*.*" >> $FTP_JOB
            echo -e "lcd $LOCAL_BAICDR\ncd ~/ARS/Forwarded\nmget -cE BAI*_CD*.*" >> $FTP_JOB
            process_ftp_job
        ;;
        *) logentry "Unknown cycle please assist..."
           mailalert "Error with SWIFT SFTP process"
           exit 1
        ;;
esac
file_maintenance
JOBEND=`date +%s`
echo -e  "\n\n\nEnd SFTP Transfers with SWIFT...\n\tTime:`date`" >> $LOG_FILE
echo -e  "\tExecution Time: $(( $JOBEND - $JOBSTART )) Seconds..." >> $LOG_FILE
rm -f $JOBPID
