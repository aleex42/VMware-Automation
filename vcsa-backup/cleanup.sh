#!/bin/bash

KEEPDAYS="14"

for dir in $(find /home/vmware/data/ -maxdepth 2 -mindepth 2 -type d -mtime +$KEEPDAYS); do

    rm -rf $dir

done
