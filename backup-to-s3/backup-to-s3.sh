#!/bin/sh

# Export some ENV variables so you don't have to type anything
export AWS_ACCESS_KEY_ID="ID"
export AWS_SECRET_ACCESS_KEY="KEY"
export PASSPHRASE="PASS"

# Your GPG key
#GPG_KEY=

# The S3 destination followed by bucket name
DEST="s3://s3.eu-central-1.amazonaws.com/BUCKET/data/"
DESTSHORT="s3://BUCKET/data/"

# Set up some variables for logging
LOGFILE="/var/log/duplicity/backup.log"
DAILYLOGFILE="/var/log/duplicity/backup.daily.log"
FULLBACKLOGFILE="/var/log/duplicity/backup.full.log"
HOST="HOST"
DATE="date +%Y-%m-%d"
MAILADDR="MAIL"
TODAY=$(date +%d%m%Y)

is_running=$(ps -ef | grep duplicity  | grep python | wc -l)

if [ ! -d /var/log/duplicity ]; then
    mkdir -p /var/log/duplicity
fi

if [ ! -f $FULLBACKLOGFILE ]; then
    touch $FULLBACKLOGFILE
fi

if [ $is_running -eq 0 ]; then
    # Clear the old daily log file
    cat /dev/null > ${DAILYLOGFILE}

    # Trace function for logging, don't change this
    trace () {
            stamp=`date +%Y-%m-%d_%H:%M:%S`
            echo "$stamp: $*" | tee -a ${DAILYLOGFILE} #2>&1
    }

    # How long to keep backups for
    OLDER_THAN="6M"

    # The source of your backup
    SOURCE="/mnt/root-snap/"

    DUPOPTIONS="-v4 --s3-use-new-style --s3-european-buckets --s3-use-multiprocessing"

    FULL=
    tail -1 ${FULLBACKLOGFILE} | grep ${TODAY} > /dev/null
    if [ $? -ne 0 -a $(date +%d) -eq 1 ]; then
            FULL=full
    fi;

    trace "Backup for local filesystem started"

    if [ ! -d /mnt/root-snap ];then
        mkdir -p /mnt/root-snap
    fi

    trace "Creating MySQL Database Backup.."
    mysqldump --defaults-file=/etc/mysql/debian.cnf --all-databases > /root/mysql-dump.sql #>> ${DAILYLOGFILE}

    lvcreate -l100%FREE -s -n root-snap /dev/vg/root
    mount /dev/vg/root-snap /mnt/root-snap

    cd "${0%/*}"

    trace "... removing old backups"

    duplicity remove-older-than ${OLDER_THAN} ${DEST} | tee -a ${DAILYLOGFILE} #2>&1

    trace "... backing up filesystem"

    if [ -f "./backup-include-dirs" ]; then
        duplicity ${FULL} --include-filelist ./backup-include-dirs --exclude '**' ${DUPOPTIONS} ${SOURCE} ${DEST} | tee -a ${DAILYLOGFILE} #2>&1
    else
        trace "ERROR: backup-include-dirs not found!"
    fi

    aws s3 ls $DESTSHORT --summarize --region eu-central-1 --human-readable | grep "Total Size" | tee -a $DAILYLOGFILE

    umount /mnt/root-snap
    rmdir /mnt/root-snap
    lvremove -f /dev/vg/root-snap

    trace "Backup for local filesystem complete"
    trace "------------------------------------"

    # Send the daily log file by email
    cat "$DAILYLOGFILE" | mail -s "Duplicity Backup Log for $HOST - $DATE" $MAILADDR
    BACKUPSTATUS=`cat "$DAILYLOGFILE" | grep Errors | awk '{ print $2 }'`
    if [ "$BACKUPSTATUS" != "0" ]; then
	   cat "$DAILYLOGFILE" | mail -s "Duplicity Backup Log for $HOST - $DATE" $MAILADDR
    elif [ "$FULL" = "full" ]; then
        echo "$(date +%d%m%Y_%T) Full Back Done" >> $FULLBACKLOGFILE
    fi

    # Append the daily log file to the main log file
    cat "$DAILYLOGFILE" >> $LOGFILE

    # Reset the ENV variables. Don't need them sitting around
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset PASSPHRASE
fi
