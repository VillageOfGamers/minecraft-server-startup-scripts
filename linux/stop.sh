#!/bin/sh

# This script is explicitly set up to send the stop command to the Minecraft server, and wait for it to die on its own.
# This gives it time to gracefully shut down so that the systemd service doesn't just kill it outright!
# Please specify the path to your mcrcon binary, as well as the command you wish to send to the server!
# This allows the following script to be used for more than just sending stop to the Minecraft server without an interactive shell.
rconpath="/usr/local/bin/mcrcon"
cmd="stop"
<<<<<<< HEAD
$rconpath -H localhost -P 25575 -p "supersecretpasswordhere" $cmd
=======
pid=`cat /bulk/Minecraft/.pid`
$rconpath -H localhost -P 25575 -p "Giantvince1" $cmd
wait $pid
sleep 10
>>>>>>> 0fa9501 (Update start_nointeract.sh and stop.sh to include proper logic surrounding PID detection and exit status detection, as well as provide a FIFO shell to the server's own input/output system. This eliminates reliability on mcrcon entirely, as the stop command can be read into the FIFO and get sent to the server that way.)
