#!/bin/bash

cd /root/backup


    umount /root/backup/root-snap
    rmdir /root/backup/root-snap
    lvremove -f /dev/vg/root-snap


    if [ ! -d /root/backup/root-snap ];then
        mkdir -p /root/backup/root-snap
    fi

    echo "creating LVM snapshot.."
    lvcreate -l100%FREE -s -n root-snap /dev/vg/root
    mount /dev/vg/root-snap /root/backup/root-snap
    echo "root-snap mounted."

    echo "Removing Logfiles from Snapshot.."
    rm -R /root/backup/root-snap/var/log

    echo "Creating MySQL Database Backup into Snapshot.."
    mysqldump --defaults-file=/etc/mysql/debian.cnf --events --all-databases > /root/backup/root-snap/root/mysql-dump.sql

    echo "Backing up list of installed packages into Snapshot.."
    dpkg --get-selections > /root/backup/root-snap/root/dpkg-installed-packages.txt



./duplicacy backup
STATUS=$?


umount /root/backup/root-snap
rmdir /root/backup/root-snap
lvremove -f /dev/vg/root-snap
echo "LVM snapshot removed."


echo "Status:"
echo $STATUS
echo "================"

if [ $STATUS -eq 0 ]
then
  echo "Backup finished." | php /root/bin/telegram.php
else
  echo "ERROR on last backup: $STATUS" | php /root/bin/telegram.php
fi

./duplicacy prune -keep 0:365 -keep 30:180 -keep 7:30 -keep 1:7
STATUS=$?
echo $STATUS
if [ $STATUS -eq 0 ]
then
  echo "Cleaned up old backups."
else
  echo "ERROR while cleaning old backups: $STATUS" | php /root/bin/telegram.php
fi
