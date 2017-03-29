#!/bin/bash
LOGFILE=/root/backup.last.log
exec > >(tee -a ${LOG_FILE} )
exec 2> >(tee -a ${LOG_FILE} >&2)
echo "Beginne Backup..."

lvcreate -l100%FREE -s -n root-snap /dev/vg/root

mkdir /mnt/root-snap
mount /dev/vg/root-snap /mnt/root-snap

export PASSPHRASE="XXXXX"

duplicity /mnt/root-snap/ sftp://username@1.2.3.4//home/USERNAME/BACKUP/backupname

unset PASSPHRASE

umount /root/root-snap
rm /mnt/root-snap

lvremove -f /dev/vg/root-snap

echo "Beende Backup."
