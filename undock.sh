#!/bin/sh
#
# undock.sh
#
# Undocks a Mac
#
# Copyright (c) 2018-2023 Matteo Corti <matteo@corti.li>
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of the Apache License v2
# See the LICENSE file for details.
#

# shellcheck disable=SC2034
VERSION=1.2.0

PREFIX='    '

usage() {

    echo
    echo "Usage: undock.sh [OPTIONS]"
    echo
    echo "Options:"
    # Delimiter at 78 chars ############################################################
    echo "   -h,--help,-?                    This help message"
    echo "   -n                              Dry run"
    echo "   -V,--version                    Version"
    echo
    echo "Report bugs to https://github.com/matteocorti/undock.sh/issues"
    echo

    exit

}

command() {
    if [ -n "${DRY_RUN}" ]; then
        echo "$ $*"
    else
        "$@" 2>&1 | sed "s/^/${PREFIX}/"
    fi
}

kill_processes() {

    volume=$1
            
    for proc in $(
                     sudo lsof |
                         grep "${volume}" |
                         grep -v mds |
                         grep -v Finder |
                         sed -e 's/^[^ ]* *//' -e 's/ .*//' |
                         sort -u
                 ); do

        procname=$(ps -o comm "${proc}" | tail -n 1)

        printf "    Trying to kill '%s' (%s)\n" "${procname}" "${proc}"

        command sudo kill "${proc}"

    done
    
}

COMMAND_LINE_ARGUMENTS=$*

while true; do

    case "$1" in
    -h | --help)
        usage
        ;;
    -n)
        DRY_RUN=1
        shift
        ;;
    -V | --version)
        echo "undock.sh version ${VERSION}"
        exit
        ;;
    *)
        if [ -n "$1" ]; then
            echo "Error: unknown option: ${1}" 1>&2
            usage
        fi
        break
        ;;
    esac

done

##############################################################################
# Stop time machine

printf 'Time machine\n'
if tmutil status | grep -q 'Running\ \=\ 1'; then

    echo '  Stopping Time Machine'
    command tmutil stopbackup

    while tmutil status | grep -q 'Running\ \=\ 1'; do

        printf "  Waiting Time Machine to stop ...\n"
        sleep 2

        # sometimes the 'stopbackup' command has to be repeated

        if tmutil status | grep -q 'Running\ \=\ 1'; then
            command tmutil stopbackup
        fi

    done

else

    printf "  Time Machine is not running\n"

fi

printf '\nExternal disks\n'

# External disks

disks=$(diskutil list external | grep '^/dev' | sed 's/ .*//')
if [ -n "${disks}" ]; then

    if mount | grep -q "${disk}" ; then
    
        # listing applications to be closed
        for disk in ${disks}; do

            
            # get the volume for the disk
            volume=$(mount | grep "^${disk}" | sed -e 's/.* on //' -e 's/ (.*//')
            
            if [ -n "${volume}" ]; then
                printf '  Killing processes accessing %s\n' "${volume}"
                kill_processes "${volume}"
            fi

        done

    fi
        
    ##############################################################################
    # Eject disks

    for disk in ${disks}; do

        if mount | grep -q "${disk}" ; then
        
            diskname=$(diskutil info "${disk}" | grep 'Media Name' | sed 's/.*Media Name: *//')
            printf '  Ejecting %s\n' "${diskname}"
            command diskutil eject "${disk}"
        fi
        
    done

    printf "  External disks ejected\n"

else

    printf "  No external disks to eject\n"

fi


printf '\nNetwork volumes\n'

# Network volumes

net_volumes=$(  mount | grep smbfs | sed -e 's/.*\ on\ //' -e 's/\ (.*//' )
if [ -n "${net_volumes}" ]; then

    # listing applications to be closed
    for net_volume in ${net_volumes}; do
        printf '  Killing processes accessing %s\n' "${net_volume}"
        kill_processes "${net_volume}"
    done

    ##############################################################################
    # Eject disks

    for net_volume in ${net_volumes}; do
        printf '  Ejecting %s\n' "${net_volume}"
        command umount "${net_volume}"
    done

    printf "  Network volumes ejected\n"

else

    printf "  No network volumes to eject\n"

fi

# Music

printf '\nStopping the music\n'
osascript -e 'tell application "Music" to pause'
