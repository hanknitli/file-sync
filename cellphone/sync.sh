#!/usr/bin/env bash

# Exit if there are any errors
set -e

# Global variables
source_flag=false
dest_flag=false
LOG_FILE="${HOME}/file-sync.log"

pretty_print(){
    local len=${#1}
    local line_separator=$(printf "%-${len}s" ' ')
    echo
    echo "${line_separator// /-}"
    printf "$1\n"
    echo "${line_separator// /-}"
    echo
}

usage() {
    if [[ ! -z ${1} ]]; then
        printf "\nInvalid option \'${1}\'\n\n" 1>&2
        error=true
    fi

	printf "Usage: ${0} -s [Source] -d [Destination]\n"
	printf "\t-h, --help\t\t\t- Show the help menu\n"
	printf "\t-s, --src [Source]\t\t- Source directory to sync\n"
	printf "\t-d, --dest [Destination]\t- Destination directory to sync\n"

    if [[ -z ${error} ]]; then
        exit 0
    else
        exit 1
    fi
}

parse_cline_args(){
    # Transform long options to short options, so that getopts can parse them
    for arg in "$@"; do
        shift
        case "$arg" in
            "--help")
                set -- "$@" "-h"
                ;;
            "--src")
                set -- "$@" "-s"
                ;;
            "--dest")
                set -- "$@" "-d"
                ;;
            *)
                set -- "$@" "$arg"
        esac
    done

    # Parse command line arguments and remove any trailing '/' in directory names
    while getopts ":hs:d:" options; do
        case ${options} in
            h)
                usage
                ;;
            s)
                source=${OPTARG%/}
                source_flag=true
                ;;
            d)
                dest=${OPTARG%/}
                dest_flag=true
                ;;
            :)
                pretty_print "[ERROR] Option -${OPTARG} needs an argument" 1>&2
                usage
                ;;
            *)
                usage ${OPTARG}
                ;;
        esac
    done

    # Check if the source is specified
    if [[ ${source_flag} = "false" ]]; then
        pretty_print "[ERROR] Source not specified" 1>&2
        usage
    fi

    # Check if the destination is specified
    if [[ ${dest_flag} = "false" ]]; then
        pretty_print "[ERROR] Destination not specified" 1>&2
        usage
    fi
}

# Do sanity check on directories before sync execution
sanity_check(){
    # Check if the specified source directory exists
    if [[ ! -d ${source} ]]; then
        printf "[ERROR] Source directory '${source}' either does not exists or is not a directory\n" 1>&2
        exit 1
    fi

    # Check if the specified destination directory exists; if not show a warning
    if [[ ! -d ${dest} ]]; then
        pretty_print "[WARN] Destination directory '${dest}' does not exists and will be created"
    fi
}

# Dry-run execution
dry_run(){
    pretty_print "[INFO] Starting sync dry-run"
    printf "Source      : ${source}\n"
    printf "Destination : ${dest}\n\n"

    rsync --dry-run -avPz --delete --omit-dir-times --no-perms \
        --size-only --human-readable --out-format="%o: %M: %f" "$source/" "$dest/" || exit_code=$?

    if [[ ! -z ${exit_code} ]]; then
        printf "[ERROR] Sync dry-run failed with error code ${exit_code}\n"
        exit ${exit_code}
    fi
}

# Sync execution
sync_exec(){
    pretty_print "[INFO] Starting sync"
    printf "Source      : ${source}\n"
    printf "Destination : ${dest}\n"
    printf "Log file    : ${LOG_FILE}\n\n"

	touch "${LOG_FILE}"
	rsync -avPz --delete --omit-dir-times --no-perms \
	    --size-only --human-readable "$source/" "$dest/" 2> >(grep -v "Operation not supported (95)") || exit_code=$?

	if [[ ! -z ${exit_code} ]]; then
		printf "[ERROR] Sync failed with error code ${exit_code}\n"
		exit ${exit_code}
	fi
}

# If the argument list is empty, just show the help
if [[ $# -eq 0 ]]; then
    usage
fi

# Parse command line arguments
parse_cline_args "$@"

# Sanity check on directories
sanity_check

# Start the dry-run execution
dry_run

# Prompt the user for sync execution
pretty_print "[INFO] Dry-run complete and the sync will be executed"
printf "Do you want to continue? (Y/y/N/n): "
read choice

if [[ ${choice} =~ ^[Yy]$ ]]; then
    sync_exec
else
	printf '\nAborted\n'
	exit 0
fi

pretty_print "[INFO] Sync successful"
