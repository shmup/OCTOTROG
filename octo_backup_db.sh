#!/bin/bash

# tar up the db and delete any backups
# older than 180 days. 180 seems like too many

tar czvf "/home/octotrog/octobackup/octodb-$(date +%F).tar.gz" /home/octotrog/.irssi/scripts/crawl.db
find /home/octotrog/octobackup -mtime +180 -type f -delete


