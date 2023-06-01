#!/bin/sh
#
# undock.sh
#
# Undocks a Mac
#
# Copyright (c) 2018-2022 Matteo Corti <matteo@corti.li>
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of the Apache License v2
# See the LICENSE file for details.
#

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

##############################################################################
# Stop Parallels

# heck if Paralles is running a VM from an external disk
if pgrep -afl '[P]arallels' | grep -q '[V]olumes'; then

    printf "Stopping Parallels"
    osascript -e 'quit app "Parallels Desktop"'

fi
printf "\rNo Parallels VMs running from an external disk\n"


##############################################################################
# Eject disks

printf 'Ejecting disks'

osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'
printf "\rDisks ejected    \n"
