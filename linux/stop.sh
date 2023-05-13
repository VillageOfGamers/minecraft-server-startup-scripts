#!/bin/sh

# This script is explicitly set up to send the stop command to the Minecraft server, and wait for it to die on its own.
# This gives it time to gracefully shut down so that the systemd service doesn't just kill it outright!
# Please specify the path to your mcrcon binary, as well as the command you wish to send to the server!
# This allows the following script to be used for more than just sending stop to the Minecraft server without an interactive shell.
rconpath="/usr/bin/mcrcon"
cmd="stop"
$rconpath -H localhost -P 25575 -p "supersecurepasswordhere" $cmd
while kill -0 $MAINPID 2>/dev/null do
	sleep 0.5
done
