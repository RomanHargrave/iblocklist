#!/bin/bash

BLOCKLIST_HOST="http://list.iblocklist.com";
PARAMS="fileformat=p2p&archiveformat=gz"

COUNT=0;
for ID in `curl -s https://www.iblocklist.com/lists.php | grep ${BLOCKLIST_HOST} | awk '{print $8}' | awk -F \= '{print $2}' | sed 's/.//;s/.$//'`; do
  ((COUNT++));
  echo "${COUNT}: Downloading: ${ID}";
  wget "${BLOCKLIST_HOST}/?list=${ID}&${PARAMS}" -O /tmp/blocklists/${ID}.gz;
done
