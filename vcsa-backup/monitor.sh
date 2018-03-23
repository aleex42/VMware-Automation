#!/bin/bash

HOST=$1

TIME=$(grep '"state":"SUCCEEDED' /home/vmware/log/backup-$HOST.log | tail -1 | awk 'BEGIN{ FS="\":\"" ; RS="," } $1 ~ "end_time" { print $2 }' | sed "s/\"//g")

TIME_UNIX=$(date -d $TIME +%s)

NOW=$(date +%s)

DIFF=$(echo $NOW - $TIME_UNIX | bc -l)
DIFF_HOURS=$(echo $DIFF/3600 | bc)

if [ $DIFF -lt "86400" ]; then {
        echo "OK: last backup $DIFF seconds (~ $DIFF_HOURS hours) ago"
        exit 0
} else {
        echo "CRITICAL: last backup more than 1 day ago (~ $DIFF_HOURS hours)"
        exit 2
}; fi
