#!/bin/sh
# shellcheck disable=SC2164,SC2086,SC2027,SC2269,SC2181,SC2034

# YOU MUST KEEP THE TOP 2 LINES OF THIS FILE INTACT! LINE 1 TELLS YOUR LINUX INSTALL WHICH SHELL THIS RUNS IN!
# LINE 2 TELLS SHELLCHECK WHICH EXACT ISSUES TO IGNORE WITHIN THIS FILE! I HAVE DEVELOPED IT WITH POSIX SH IN MIND!
# Please note the majority of this file's size directly comes from all these comment lines inside it.
# If you wish to shrink this file, the easiest way to do so, without losing any function, is to cut out the comments.
# Any and all lines beginning with a # EXCEPT THE TOP ONE may be removed.

# This variable directly specifies whether or not to enable the script's Download Mode logic.
# If this variable is set to 0, this script will NOT check for or download new server JAR releases.
# This also means that this script CANNOT ask to re-enable this function if it is disabled here!
# However, if this toggle is enabled, as per default, you MAY disable it via prompts during execution.
# All of those prompts will ONLY disable Download Mode on a PER-RUN BASIS however! It will NOT be permanent!
download=1

# This is the path to the server itself. I recommend having this be an absolute path.
# The reason I have it showing "./" is to point it to the "current" directory.
# This means it will evaluate the server to be located inside the directory you get if you run pwd just before this script.
# This is a sensible default, as the script is designed to check if the variable is the default.
# If this variable is not the default, the script has a check in place to see if the initial working directory actually holds the server.
# The script will complain to you if that happens and this variable is not "./", but it will allow you to continue still.
serverdir="./"

# This is the argument list the server starts with. I recommend ONLY changing the options in the arglist and jarname variables.
# The rest of the arguments have been fine-tuned by the Minecraft community to improve garbage collection timing.
# This results in overall better performance of the server and nearly completely removes the lag spikes you would otherwise see.

# The jarname variable specifies which file the Java runtime executes first. You generaly want this to be a RELATIVE path (i.e. "./server.jar" is a relative path).
# The -Xms#G argument specifies how much memory to allocate upon starting the Java instance.
# The -Xmx#G argument specifies the MAXIMUM amount of memory to allocate to the Java instance, NOT including overhead.
# The overhead you see on this will be around 256MB, give or take.

# I recommend leaving 1GB of RAM or more available if you are using Linux without a graphical environment.
# If you are using a desktop environment in Linux, leave 2GB of RAM or more available for the OS.
# This script is NOT usable in Windows; it is expressly designed with the Linux shell in mind.
# Please edit arglist to allocate the appropriate amount of RAM for YOUR specific system!
# The general consensus is that you shouldn't need more than 8GB of RAM unless some of your plugins are going nuts (Dynmap takes a lot for example).
# You may expand the RAM capacity further if you're REALLY wanting to stretch how much data FAWE (or normal WorldEdit) can hold in the buffer at one time.
# Also see the comments for fullarglist below; these tips are necessary!
jarname="./server.jar"
arglist="-Xms12G -Xmx12G -jar $jarname"

# THESE VARIABLES ARE NOT TO BE TOUCHED UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING!
# These arguments for the Java instance have been hand-tuned by the Minecraft community to provide optimal performance of the server.
# The user-adjustable argument list is ABOVE these comment lines; those control how much RAM it can use, and the name of the JAR to launch.
gctuningbig="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
gctuningsmall="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"

# If you are using this to start a Minecraft server with LESS THAN 12GB OF RAM, please use gctuningsmall instead of gctuningbig.
# gctuningsmall is set up so that the server doesn't get starved of RAM on lower RAM allocation, and is beneficial for a low-RAM system.
fullarglist="$gctuningbig $arglist"

# This olddir variable is to store the initial working directory this script got launched from.
# This is because the script DOES change which directory the shell uses if the serverdir variable above is NOT set to ./ per its default.
# Note: This does NOT mean the directory the FILE sits in, it means the path your SHELL'S current working directory was at the time this script got started.
olddir=$(pwd)

# This function is what handles all the logic behind the download mode in this script.
# Without this function, the server would be completely unable to fetch new versions of the Minecraft server.
# It contains all the necessary variables within it, and is either on or off based on the download variable up at the top.
# If it's off, it will not proceed with checking or initializing any of the needed variables for download, but will just start the server as-is.

pre_init () {
	if [ $download = 1 ]; then
		mcver="1.19.4"
		baseurl="https://api.papermc.io/v2/projects/paper/versions/"$mcver
		build="$(curl -sX GET "$baseurl"/builds -H 'accept: application/json' | jq '.builds [-1].build')"
		dlbuild=$baseurl"/builds/"$build"/downloads/paper-"$mcver"-"$build".jar"
		oldbuild=$(grep . ./.version)
		if [ $oldbuild != $build ]; then
			wget $dlbuild -O $jarname > /dev/null 2>&1
			if [ $? = 0 ]; then
				echo $build > ./.version
				start_server
			else
				exit 1
			fi
		else
			start_server
		fi
	else
		start_server
	fi
}

# This function below handles the preliminary checks to start the server, and will get everything up and running.
# It also directly handles all of the necessary logic to detect any problems within the environment and exit with status 1 if a problem arises.
# This is all optimized to be run by a background script or service, and not something the user faces head-on.

start_server () {
	if [ $serverdir = ./ ]; then
		test -f $jarname
		error=$?
		notfound=$error
		invalidpath=$error
	else
		cd $serverdir
		inaccessible=$?
		if [ $inaccessible = 0 ]; then
			test -f $jarname
			invalidpath=$?
		fi
		cd $olddir && test -f $jarname
		notfound=$?
	fi
	if [ $invalidpath = 0 ]; then
		test -f ./eula.txt
		firstrun=$?
	elif [ $invalidpath = 1 ] && [ $notfound = 0 ]; then
		cd $olddir
		test -f ./eula.txt
		firstrun=$?
	else
		exit 1
	fi
	if [ $firstrun = 1 ]; then
		java $fullarglist >output.log 2>error.log &
		pid=$!
		echo $pid > ./.pid
		wait $pid
		tail --pid=$pid -f ./.shell
		rm ./.shell ./.pid
		exit 0
	else
		grep true ./eula.txt
		noeula=$?
		if [ $noeula = 0 ]; then
			test -f ./.running
			noconflict=$?
			if [ $noconflict = 1 ]; then
				touch ./.running
				error=$?
				if [ $error = 1 ]; then
					exit 1
				else
				java $fullarglist >output.log 2>error.log &
				pid=$!
				echo $pid > ./.pid
				wait $pid
				serverexit=$?
				rm ./.running ./.shell ./.pid
				fi
			else
				exit 1
			fi
		else
			exit 1
		fi
	fi
}

# These 2 lines right here are just how everything gets brought up. The exit command will force the script to reflect the exit code of the server.
# This is so you can see what the Minecraft server's final exit status was, after having been started and stopped (or if it crashed).
pre_init
exit $serverexit
