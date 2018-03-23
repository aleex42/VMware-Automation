#!/bin/bash

# --
# Backup VMware VCSA 
# --
# Copyright (C) 2018 Alexander Krogltoh, E-Mail: git <at > krogloth.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

# modified and bugfixed version of
# https://pubs.vmware.com/vsphere-6-5/index.jsp?topic=%2Fcom.vmware.vsphere.vcsapg-rest.doc%2FGUID-222400F3-678E-4028-874F-1F83036D2E85.html
# official VMware VCSA backup script


VC_ADDRESS=$1
VC_USER="administrator@vsphere.local"
VC_PASSWORD="xxxxxxx"
SCP_ADDRESS="scp-backup-fqdn.example.com"
SCP_USER="vmware"
SCP_PASSWORD="xxxxxxx"

BACKUP_LOG="log/backup-$VC_ADDRESS.log"
COOKIES="log/cookies-$VC_ADDRESS.txt"
############################

cd /home/vmware/

curl -u "$VC_USER:$VC_PASSWORD" \
   -X POST -s \
   -k --cookie-jar $COOKIES \
   "https://$VC_ADDRESS/rest/com/vmware/cis/session" 2>&1 >/dev/null

TIME=$(date +%Y-%m-%d-%H-%M-%S)
cat << EOF >log/task-$VC_ADDRESS.json
{ "piece":
     {
         "location_type":"SCP",
         "comment":"Automatic backup",
         "parts":["seat"],
         "location":"scp://$SCP_ADDRESS/home/vmware/data/$VC_ADDRESS/$TIME",
         "location_user":"$SCP_USER",
         "location_password":"$SCP_PASSWORD"
     }
}
EOF

echo Starting backup $TIME >>$BACKUP_LOG
curl -k --cookie $COOKIES \
   -H 'Accept:application/json' \
   -H 'Content-Type:application/json' \
   -X POST \
   --data @log/task-$VC_ADDRESS.json 2>>$BACKUP_LOG >log/response-$VC_ADDRESS.txt \
   "https://$VC_ADDRESS/rest/appliance/recovery/backup/job"
cat log/response-$VC_ADDRESS.txt >>$BACKUP_LOG
echo '' >>$BACKUP_LOG

ID=$(awk 'BEGIN{ FS=":" ; RS="," } $1 ~ "id" { ID = $2 } END { print ID }' log/response-$VC_ADDRESS.txt | sed "s/[\"}]//g" | tr -d "\n\r")

echo 'Backup job id: '$ID >>$BACKUP_LOG

PROGRESS="INPROGRESS"
ROUND="1"
until [ "$PROGRESS" != "INPROGRESS" ]
do
     sleep 60s
     echo "Round $ROUND" >>$BACKUP_LOG
     ((ROUND++))
     curl -k --cookie $COOKIES \
       -H 'Accept:application/json' \
       --globoff -s \
       "https://$VC_ADDRESS/rest/appliance/recovery/backup/job/$ID" \
       >log/response-$VC_ADDRESS.txt
     cat log/response-$VC_ADDRESS.txt >>$BACKUP_LOG
     echo ''  >>$BACKUP_LOG
     PROGRESS=$(awk 'BEGIN{ FS=":" ; RS="," } $1 ~ "state" { print $2 }' log/response-$VC_ADDRESS.txt | sed "s/\"//g") 
     echo 'Backup job state: '$PROGRESS >>$BACKUP_LOG
done

echo "Backup job completion status: $PROGRESS" >>$BACKUP_LOG
echo ''  >>$BACKUP_LOG
