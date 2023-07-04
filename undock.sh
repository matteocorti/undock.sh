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
VERSION=1.0.2

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
        echo "$ $1"
    else
        $1
    fi
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
        echo ".sh version ${VERSION}"
        exit
        ;;
    *)
        if [ -n "$1" ]; then
            echo "Error: unknown option: ${1}" 1>&2
            usage
            exit 1
        fi
        break
        ;;
    esac

done

##############################################################################
# Stop time machine

if tmutil status | grep -q 'Running\ \=\ 1'; then

    echo 'Stopping Time Machine'
    command "tmutil stopbackup"

    while tmutil status | grep -q 'Running\ \=\ 1'; do

        printf "  Waiting Time Machine to stop ...\n"
        sleep 2

        # sometimes the 'stopbackup' command has to be repeated

        if tmutil status | grep -q 'Running\ \=\ 1'; then
            command "tmutil stopbackup"
        fi

    done

fi

printf "Time Machine is not running\n"

##############################################################################
# Try to kill processes accessing external disks

# list external disks
disks=$(diskutil list external | grep '^/dev' | sed 's/ .*//')

if [ -n "${disks}" ]; then

    # listing applications to be closed
    for disk in ${disks}; do

        # get the volume for the disk
        volume=$(mount | grep "^${disk}" | sed -e 's/.* on //' -e 's/ (.*//')

        if [ -n "${volume}" ]; then
            printf "Killing processes accessing %s\n" "${volume}"

            for proc in $(sudo lsof | grep "${volume}" | sed -e 's/^[^ ]* *//' -e 's/ .*//' | sort -u); do

                procname=$(ps -o comm "${proc}" | tail -n 1)

                printf "  Trying to kill %s\n" "${procname}"

                command "kill ${proc} >/dev/null 2>&1"

            done

        fi

    done

    ##############################################################################
    # Eject disks

    printf 'Ejecting external disks:\n'

    for disk in ${disks}; do
        diskname=$(diskutil info "${disk}" | grep 'Media Name' | sed 's/.*Media Name: *//')
        printf '  Ejecting %s\n' "${diskname}"
        command "diskutil eject ${disk} >/dev/null 2>&1"
    done

    printf "External disks ejected\n"

else

    printf "No external disks to eject\n"

fi
