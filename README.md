# useful-server-scripts
Some, you guessed it, useful scripts for web/mail servers. Include diskspace check, backup with duplicity and sending login alerts per mail.

## hddspace.sh ##
add the following line to your /etc/crontab file to run the disk space check once per hour:

    0	*	*	*	*	root    sh /root/hddspace.sh
---
## backup.sh ##
add the following line to your /etc/crontab file to run the backupscript every sunday:

    20	3	*	*	7	root	/root/backup.sh
---
## backup2s3.sh ##
this script (found and modified) uses duplicity to backup your data to s3 space

it uses duplicity and awscli

install and configure the requirements first:

    apt-get install python-pip
    pip install boto
    pip install awscli
    aws configure
    
---
## blacklist-check.sh ##
add the following to your /etc/crontab file:

    #m	h	dom	mon	dow	user	cmd
    10	4	*	*	*	root	/root/blacklist-check.sh -H 1.2.3.4
---
