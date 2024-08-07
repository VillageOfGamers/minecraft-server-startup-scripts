#!/bin/sh

# This script is explicitly set up to send the stop command to the Minecraft server, and wait for it to die on its own.
# This gives it time to gracefully shut down so that the systemd service doesn't just kill it outright!
# Please specify the path to your mcrcon binary, as well as the command you wish to send to the server!
# This allows the following script to be used for more than just sending stop to the Minecraft server without an interactive shell.
rconpath="/usr/local/bin/mcrcon"
cmd="stop"
pid=$(cat /path/to/server/.pid)
$rconpath -H localhost -P 25575 -p "supersecretpasswordhere" $cmd
wait $pid
sleep 10
