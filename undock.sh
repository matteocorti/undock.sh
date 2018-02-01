#!/bin/sh
#
# undock.sh
#
# Undocks a Mac
#
# Copyright (c) 2018 Matteo Corti <matteo@corti.li>
#
# This module is free software; you can redistribute it and/or modify it
# under the terms of the Apache Licese v2
# See the LICENSE file for details.
#

##############################################################################
# Stop time machine

if tmutil status | grep -q 'Running\ \=\ 1' ; then

    echo 'Stopping Time Machine'
    tmutil stopbackup

    while tmutil status | grep -q 'Running\ \=\ 1' ; do
	printf '  waiting Time Machine to stop ...\n'
	sleep 2
    done

else

    echo 'Time Machine is not running'
    
fi

##############################################################################
# Eject disks

echo 'Ejecting disks'

osascript -e 'tell application "System Events"' -e 'set diskNames to the name of every disk whose ejectable is true' -e 'copy result to stdout' -e 'end tell' |
    grep '[[:alpha:]]' |
    sed 's/,\ /,/' |
    tr ',' '\n' |
    sort |
    uniq |
    sed 's/^/\ \ /'

osascript -e 'tell application "Finder" to eject (every disk whose ejectable is true)'
