#!/bin/sh
#
# undock.sh
#
# Undocks a Mac
#
# Copyright (c) 2018-2021 Matteo Corti <matteo@corti.li>
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of the Apache Licese v2
# See the LICENSE file for details.
#

##############################################################################
# Stop time machine

if tmutil status | grep -q 'Running\ \=\ 1'; then

    echo 'Stopping Time Machine'
    tmutil stopbackup

    while tmutil status | grep -q 'Running\ \=\ 1'; do

        printf '  waiting Time Machine to stop ...\n'
        sleep 2

        # sometimes the 'stopbackup' command has to be repeated

        if tmutil status | grep -q 'Running\ \=\ 1'; then
            tmutil stopbackup
        fi

    done

else

    echo 'Time Machine is not running'

fi

##############################################################################
# Quit VM Ware Fusion

echo 'Quitting VMware Fusion'
osascript -e 'quit app "VMware Fusion"'

##############################################################################
# Quit Parallels

echo 'Quitting Parallels'
osascript -e 'quit app "Parallels Desktop"'

##############################################################################
# Eject disks

echo 'Ejecting disks'

osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'
