#!/bin/bash
#
# Script checks used space on mounted drives and sends an email if
# its over the ALERT level (percent)
#
NAME="Server Name"
ADMIN="mail@domain.de"
ALERT=80
df -H | awk '
    NR == 1 {next}
    $1 == "abc:/xyz/pqr" {next}
    $1 == "tmpfs" {next}
    $1 == "rootfs" {next}
    $1 == "/dev/cdrom" {next}
    1 {sub(/%/,"",$5); print $1, $5}
' | while read filesystem percentage; do
    if [ "$percentage" -ge "$ALERT" ]; then
      mail -s "[Alert on $NAME] Almost out of disk space ($percentage%) on $filesystem" "$ADMIN"
      #echo "[Alert on $NAME] Almost out of disk space ($percentage%) on $filesystem"
    fi
done
