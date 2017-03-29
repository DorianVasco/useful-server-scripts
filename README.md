# useful-server-scripts
Some, you guessed it, useful scripts for web/mail servers. Include diskspace check, backup with duplicity and sending login alerts per mail.

## hddspace.sh ##
add the following line to your /etc/crontab file to run the disk space check once per hour:
> 0	*	*	*	*	root    sh /root/hddspace.sh
---
## backup.sh ##
add the following line to your /etc/crontab file to run the backupscript every sunday:
> 20	3	*	*	7	root	/root/backup.sh
