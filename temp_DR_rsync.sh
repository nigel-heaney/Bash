#!/bin/bash
############################################################################
# Filename:     rsync.sh
# Written by:   Nigel Heaney
# Decription:   Geneic rsync scritp, used for DR replication and other
#
# Version:      1.0
# Date:         13/3/2012
#
############################################################################

# Custom Variables
EXCLUDEFILE=/x/y/conf/x_DR_rsync_exclusions.txt
SOURCEDIR=/data/wss/xx/xxprod/
DESTDIR=$USER@$DR_HOST:$WHOME
DESTDESCRIPTION="XX-DR"

# generic variables
LOG_FILE=$SOURCEDIR/rsync/${DESTDESCRIPTION}_rsync-`date +%j-%H%M`.log
EMAIL="a@d.local"

### General
logentry() {
    echo -e "`date +\"%T\"`: $1" >> $LOG_FILE
}

mailalert() {
    uuencode $LOG_FILE $LOG_FILE | mail -s"`hostname` - $1" $EMAIL
}

run_rsync() {
    # rsync prod to DR, use exclude file to filter out stuff to replicate
    /usr/bin/rsync -avlprog --delete $SOURCEDIR $DESTDIR --exclude-from=$EXCLUDEFILE >> $LOG_FILE
}

### MAIN ###
echo -e "START: `date`\n####################################################################################\n" > $LOG_FILE

#if exludes is missing then exit, we dont want to overwrite protected areas!
if [ ! -e $EXCLUDEFILE ]; then
    logentry "ERROR: Exclude file missing, abandoning replication to $DESTDESCRIPTION"
    mailalert "ERROR: Exclude file missing, abandoning replication to $DESTDESCRIPTION"
    exit 1
fi
mkdir -p $SOURCEDIR/rsync > /dev/null 2>&1

run_rsync
echo -e "\n####################################################################################\nEND: `date`" >> $LOG_FILE
echo "Finished: Logfile = $LOG_FILE"
# rsync the rsync job across for chekcing purposes.
/usr/bin/rsync -avlprog --delete ${SOURCEDIR}rsync $D{ESTDIR}/rsync --exclude-from=$EXCLUDEFILE >> $LOG_FILE

