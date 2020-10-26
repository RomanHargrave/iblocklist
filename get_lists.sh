#!/bin/bash

BLOCKLIST_HOST="http://list.iblocklist.com";
PARAMS="fileformat=p2p&archiveformat=gz"
tempFolder="/tmp/blocklists"
decompress=true

if [[ ! -d "$tempFolder" ]]; then

	mkdir $tempFolder;

fi

cd $tempFolder
# Get all lists from iblocklist.com
curl -m 30 -s https://www.iblocklist.com/lists.xml | xml_pp > $tempFolder/iblocklistslist.xml

# Get all lists that can be fetched without subscriptions
grep -E "<subscription>|<list>|<name>" $tempFolder/iblocklistslist.xml | grep "<subscription>false</subscription>" -B2 | grep -E "<list>|<name>" | awk '{print $1}' | sed 'N;s/\n/ /' | sed 's/<\/list> <name>/:/g' | sed 's/<list>//g' | sed 's/<\/name>//g' > $tempFolder/iblocklistslist_IDs_names.xml

COUNT=0;
for ID in `cat $tempFolder/iblocklistslist_IDs_names.xml`; do

	((COUNT++));
	IFS=":" names=( $ID )
	echo "${COUNT}: Downloading: ${names[1]}";
	wget "${BLOCKLIST_HOST}/?list=${names[0]}&${PARAMS}" --wait=2 --random-wait --tries=2 --timeout=30 -O /tmp/blocklists/${names[1]}.gz;
	
	if [ "$decompress" == true ]; then

		echo "Extracting: ${names[1]}"
		gunzip ${names[1]}.gz

	fi

done

exit 0
