#!/usr/bin/sh

# tar up the db and delete any backups
# older than 180 days. 180 seems like too many

backup_file="$BACKUPS/octodb-$(date +%F).tar.gz"

tar czf "$backup_file" "$DB"
echo "created... $backup_file"

find "$BACKUPS" -mtime +180 -type f -exec echo "removed... {}" \; -exec rm {} \;
