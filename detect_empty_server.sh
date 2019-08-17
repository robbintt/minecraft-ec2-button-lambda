#!/bin/bash

# to be installed as systemd service or shell script on ec2 server used for minecraft service

FILE="elapsed_time_empty.dat"

PLAYER_COUNT="$(lsof -iTCP:25565 -sTCP:ESTABLISHED | wc -l)"
# note that this actually is off by 1 if > 0 so if you actually want to use it you need to subract 1 if != 0
# optionally you could find a lsof flag to not show the header line or sed out the header line
echo PLAYER_COUNT: $PLAYER_COUNT

TIME_NOW=$(date +%s)
#SHUTDOWN_SECONDS=$(expr 15) # .25 mins
SHUTDOWN_SECONDS=$(expr 15 \* 60) # 15 mins

if test -f "$FILE"; then
    SECONDS_EMPTY=$(expr $TIME_NOW - $(cat $FILE))
    echo SECONDS_EMPTY: $SECONDS_EMPTY
    if [[ PLAYER_COUNT -eq "0" ]]; then
        if [[ $SECONDS_EMPTY -gt $SHUTDOWN_SECONDS ]]; then
            # reset seconds
            rm -f $FILE
            # stop the server
        echo "$SECONDS_EMPTY elapsed elapsed of $SHUTDOWN_SECONDS seconds"
            echo "Stop the instance."
        else
            echo "$SECONDS_EMPTY elapsed elapsed of $SHUTDOWN_SECONDS seconds"
            echo "Not ready to shutdown yet - keep waiting."
        fi
    else
        # there are players, reset the timer
        echo $TIME_NOW > $FILE
    fi
else
    # create the file and start the timer
    echo $TIME_NOW > $FILE
fi
