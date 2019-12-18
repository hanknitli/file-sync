#!/bin/bash

function usage() {
	echo "Usage: $0 -s [Souce] -d [Destination]"
	echo "	-s [Source]	- Source directory to sync"
	echo "	-d [Destination	- Destination directory to sync"
	exit 0
}

source_flag=false
dest_flag=false
LOG_FILE="${HOME}/hank-sync.log"

while getopts ":s:d:" option;
do
	case ${option} in
		s )
		  source=${OPTARG%/}
		  source_flag=true
		;;
		d )
		  dest=${OPTARG%/}
		  dest_flag=true
		;;
		: )
		  echo "Option -${OPTARG} needs an argument" 1>&2
		  exit 1
		;;
		\? )
		  echo "Invalid option '-$OPTARG'"
		  usage
	esac
done

if ! $source_flag; then
	echo 'Not enough options'
	usage
	exit 1
fi

if ! $dest_flag; then
	echo 'Not enough options'
	usage
	exit 1
fi

if ! [ -d "$source" ]; then
	echo "Source directory '$source' does not exist"
	exit 1
fi

if ! [ -d "$dest" ]; then
	echo "Warning: Destination directory '$dest' does not exist and will be created"
	echo
fi

echo
echo "Starting sync dry-run from $source to $dest"
rsync --dry-run -avPz --delete --human-readable --out-format="%o: %M: %f" "$source/" "$dest/"

echo
echo -n "Do you want to continue? (Y/y/N/n): "
read choice

if [[ $choice =~ ^[Yy]$ ]]; then
	echo "Look inside $LOG_FILE for all logs"
	touch "${LOG_FILE}"
	rsync -avPz --delete --human-readable --log-file=$LOGFILE "$source/" "$dest/"
	exit_code=$?

	if [ $exit_code -ne 0 ];then
		echo "Sync failed with error code $exit_code"
		exit 1
	fi
else
	echo 'Abort'
fi
