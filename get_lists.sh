#!/bin/bash

BLOCKLIST_HOST="http://list.iblocklist.com";
PARAMS="fileformat=p2p&archiveformat=gz"
tempFolder="/tmp/blocklists"
decompress=true

if [[ ! -d "$tempFolder" ]]; then

	mkdir $tempFolder;

fi

cd $tempFolder

#Use existing file as local cache for 10 days
find $tempFolder/iblocklistslist.xml -mtime +10 -exec rm {} \;

# Get all lists from iblocklist.com if cache expired
[[ -e $tempFolder/iblocklistslist.xml ]] || { curl -m 30 -s https://www.iblocklist.com/lists.xml | xml_pp > $tempFolder/iblocklistslist.xml; }

# Get all lists that can be fetched without subscriptions
grep -E "<subscription>|<list>|<name>" $tempFolder/iblocklistslist.xml | grep "<subscription>false</subscription>" -B2 | grep -E "<list>|<name>" | awk '{print $1}' | sed 'N;s/\n/ /' | sed 's/<\/list> <name>/:/g' | sed 's/<list>//g' | sed 's/<\/name>//g' > $tempFolder/iblocklistslist_IDs_names.xml

#In case no filter was set, we will be able to download whole list
cat $tempFolder/iblocklistslist_IDs_names.xml > $tempFolder/iblocklistslist_to_download.xml

#Added input Validator
#https://stackoverflow.com/questions/36926999/removing-all-special-characters-from-a-string-in-bash
validInput="$(echo "$1" | sed 's/[^a-z  A-Z 0-9]//g')"
if [ "$validInput" = "" ] && [ ! -z "$1" ]; then

	echo "Seems you use only Special Characters, currently only a-z, A-Z and digits are supported"
	exit 0

fi

if [ "$validInput" != "" ]; then

	#Check if multiple words are separated by spaces
	case "$validInput" in
		*\ * )
			multipleInput=$(echo "$validInput" | tr ' ' '|')
			#will display exact mutliple match, or an error message
			if ! grep -E "$multipleInput" "$tempFolder/iblocklistslist_IDs_names.xml" > $tempFolder/iblocklistslist_to_download.xml; then

				echo "Hmmm, nothing was found based on your input"
				exit 0

			fi
		;;
		*)
			#will display exact match, or an error message
			if ! grep "$validInput" "$tempFolder/iblocklistslist_IDs_names.xml" > $tempFolder/iblocklistslist_to_download.xml; then

				echo "Hmmm, nothing was found based on your input"
				exit 0

			fi
		;;
	esac

fi

echo "Found $(wc -l $tempFolder/iblocklistslist_to_download.xml | awk '{print $1}') possible lists to donwload"

COUNT=0;
for ID in `cat $tempFolder/iblocklistslist_to_download.xml`; do

	((COUNT++));
	IFS=":" names=( $ID )
	echo "${COUNT}: Downloading: ${names[1]}";
	wget "${BLOCKLIST_HOST}/?list=${names[0]}&${PARAMS}" --wait=2 --random-wait --tries=2 --timeout=30 -O $tempFolder/${names[1]}.gz;
	
	if [ "$decompress" == true ]; then

		echo "Extracting: ${names[1]}"
		gunzip ${names[1]}.gz

	fi

done

#clean up
#[[ -e $tempFolder/iblocklistslist.xml ]] && { rm $tempFolder/iblocklistslist.xml; }
[[ -e $tempFolder/iblocklistslist_IDs_names.xml ]] && { rm $tempFolder/iblocklistslist_IDs_names.xml; }
[[ -e $tempFolder/iblocklistslist_to_download.xml ]] && { rm $tempFolder/iblocklistslist_to_download.xml; }

exit 0
