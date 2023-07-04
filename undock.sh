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

##############################################################################
# Stop time machine

if tmutil status | grep -q 'Running\ \=\ 1'; then

    echo 'Stopping Time Machine'
    tmutil stopbackup

    while tmutil status | grep -q 'Running\ \=\ 1'; do

        printf '\rWaiting Time Machine to stop ...'
        sleep 2

        # sometimes the 'stopbackup' command has to be repeated

        if tmutil status | grep -q 'Running\ \=\ 1'; then
            tmutil stopbackup
        fi

    done

fi

printf "\rTime Machine is not running       \n"

disks=$(diskutil list external | grep '^/dev' | sed 's/ .*//')

if [ -n "${disks}" ]; then

    # listing applications to be closed
    for disk in ${disks}; do

        volume=$(mount | grep "^${disk}" | sed -e 's/.* on //' -e 's/ (.*//')

        if [ -n "${volume}" ]; then
            printf "Killing processes accessing >>>%s<<<\n" "${volume}"

            for proc in $(sudo lsof | grep "${volume}" | sed -e 's/^[^ ]* *//' -e 's/ .*//' | sort -u); do

                procname=$(ps -o comm "${proc}" | tail -n 1)

                printf "  Trying to kill %s\n" "${procname}"

                kill "${proc}" >/dev/null 2>&1

            done

        fi

    done

    ##############################################################################
    # Eject disks

    printf 'Ejecting external disks:\n'

    for disk in ${disks}; do
        diskname=$(diskutil info "${disk}" | grep 'Media Name' | sed 's/.*Media Name: *//')
        printf '  Ejecting %s\n' "${diskname}"
        diskutil eject "${disk}" >/dev/null 2>&1
    done

    printf "External disks ejected\n"

else

    printf "No external disks to eject\n"

fi
