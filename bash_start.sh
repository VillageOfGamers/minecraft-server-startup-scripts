#!/bin/bash

# YOU MUST KEEP THE TOP LINE OF THIS FILE INTACT! IT TELLS YOUR LINUX INSTALL WHICH SHELL THIS RUNS IN!
# Please note the majority of this file's size directly comes from all these comment lines inside it.
# If you wish to shrink this file, the easiest way to do so, without losing any function, is to cut out the comments.
# Any and all lines beginning with a # EXCEPT THE TOP ONE may be removed.

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
# This script is NOT usable in Windows; it is expressly designed with the Linux BASH shell in mind.
jarname="./server.jar"
arglist="-Xms4G -Xmx4G -jar $jarname"

# THESE VARIABLES ARE NOT TO BE TOUCHED UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING!
# These arguments for the Java instance have been hand-tuned by the Minecraft community to provide optimal performance of the server.
# The user-adjustable argument list is ABOVE these comment lines; those control how much RAM it can use, and the name of the JAR to launch.
gctuning="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
fullarglist="$gctuning $arglist"

# This olddir variable is to store the initial working directory this script got launched from.
# This is because the script DOES change which directory the shell uses if the serverdir variable above is NOT set to ./ per its default.
# Note: This does NOT mean the directory the FILE sits in, it means the path your SHELL'S current working directory was at the time this script got started.
olddir=$(pwd)

# This one-liner is specifically to enable case-insensitive matching for some BASH built-in items.
# It will NOT affect your normal environment. If you don't have nocasematch set, it will not be set from just running this script.
shopt -s nocasematch

# This function is just a wait loop, with the i variable getting set by whichever part of the script calls it.
# The i variable is the number of seconds to wait via this loop, while printing a countdown each second.
countdown () {
	i=$1
	while [[ i -gt 0 ]]; do
		echo "$i..."
		i=$((i-1))
		sleep 1
	done
}

# This small function is simply to ask the user if they wish to restart the Minecraft server.
# I have a catch-all case for key presses that are NOT a Y or N, which redirect the user through the question again.
# This is not meant to be an annoyance, but rather a simple way to make sure the user has properly chosen an answer.
ask_restart () {
	read -s -n 1 restart
	case $restart in
		Y*)
			echo "Beginning restart procedure. Skipping warning about closing running shell."
			server_start
			invalid=0
		;;
		N*)
			echo "Thank you for using Giantvince1's Minecraft server startup automator!"
			echo "We hope to see you soon! Exiting script in 5..."
			sleep 1
			countdown 4
			invalid=0
			exit
		;;
		*)
			echo "Invalid choice. Your choices are yes (Y) or no (N)."
			invalid=1
		;;
	esac
}

# This small function is designed to ask the user if they plan to make any changes to this file.
# The reason being, if they DO make a change to this file while it is in use, the change will NOT be reflected in the running shell.
# Instead, the shell will retain the old copy of the file and continue to use THAT one to try to run the Minecraft server.
# So, I have to ask if the user plans to modify the file so that I can ensure the script gets stopped and restarted properly.
ask_modify () {
	read -s -n 1 changes
	case $changes in
		Y*)
			if [[ $loopcounter -gt 1 ]]; then
				echo "Since you plan on changing things, this script will not loop again."
			else
				echo "Since you plan on changing things, this script will not loop."
			fi
			echo "Once you finish editing the variables, please restart the script manually."
			echo "Please press any key to exit..."
			read -s -n 1
			invalid=0
			exit
		;;
		N*)
			if [[ $loopcounter -gt 1 ]]; then
				echo "Since you don't plan on changing anything, the script is able to loop again."
			else
				echo "Since you don't plan on changing anything, the script is able to loop."
			fi
			echo "This is by design; this script is capable of re-using itself infinitely."
			echo "It will also only do so each time the user WANTS it to. It will not forkbomb."
			echo "Would you like to restart the Minecraft server? (Y/N)"
			invalid=0
			ask_restart
			while [[ $invalid = 1 ]]; do
				ask_restart
			done
		;;
		*)
			echo "Invalid choice. Your choices are yes (Y) or no (N)."
			invalid=1
		;;
	esac
}

# This function handles the post-server-run side of things, including user interaction and looping.
# You can edit the text in the echo commands to say what you want and/or need, but keep the meaning similar!
# Otherwise you may very well confuse someone who uses your modified version of this script.
after_server_exit () {
	while [[ $serverexit = 0 ]]; do
		echo "The server has been shut down. Do you wish to change any variables? (Y/N)"
		ask_modify
	done
	echo "The server has encountered some sort of error. Please check the console logs."
	echo "This script will NOT be offering you the ability to restart the server."
	echo "I recommend you look through the server logs and look for errors."
	echo "This script will exit, however you may still read the server console log."
	echo "This script exiting itself should not close the terminal window."
	echo "However, in case that were to happen, there is a failsafe in this script."
	read -s -n 1 -p "Press any key to exit..."
}

# This gigantic function is what handles all the pre-start checks for the Minecraft server.
# It also handles most of the user interaction before it actually launches the server itself.
# Unless you are adept at reading and writing BASH scripts, I HIGHLY recommend not touching this!
# You may change the text inside the echo commands, but I recommend you keep their meaning similar!
# You may easily confuse someone using your modified version of this script.
# The echo commands provide useful information to the end user based on the conditions the checks find.
server_start () {
	loopcounter=$((loopcounter+1))
	if [[ $serverdir = ./ ]]; then
		test -f $jarname
		notfound=$?
		invalidpath=$notfound
	else
		cd $serverdir && test -f $jarname
		invalidpath=$?
		cd $olddir && test -f $jarname
		notfound=$?
	fi
	if [[ $invalidpath = 0 && $notfound = 0 ]]; then
		test -f ./eula.txt
		firstrun=$?
	elif [[ $invalidpath = 1 && $notfound = 0 ]]; then
		echo "[WARN] This script could locate your Minecraft server."
		echo "[WARN] However, it found the server where you started the script from."
		echo "[WARN] This should not be intentional. Printing current variables..."
		echo "[WARN] Please set the serverdir variable to the correct path."
		echo "serverdir: $serverdir"
		echo "olddir: $olddir"
		echo "jarname: $jarname"
		echo "arglist: $arglist"
		echo -e
		echo "Press ctrl+C now if you wish to fix the issue, or press any key to continue."
		read -s -n 1
		echo "Continuing execution..."
		test -f ./eula.txt
		firstrun=$?
	else
		echo "[ERROR] This script cannot locate your Minecraft server!"
		echo "[ERROR] Printing current script variables so the issue may be found..."
		echo "serverdir: $serverdir"
		echo "olddir: $olddir"
		echo "jarname: $jarname"
		echo "arglist: $arglist"
		echo -e
		echo "Please ensure these variables are correct, and modify them accordingly."
		read -s -n 1 -p "Press any key to exit..."
		exit
	fi
	if [[ $firstrun = 1 ]]; then
		echo "Welcome to the Minecraft community, and your new Minecraft server!"
		echo "You will be required to accept the EULA in order to run the server."
		echo "The server will run in the next 10 seconds so the EULA file can be generated."
		echo "Do not delete the eula.txt file, as the server checks for it on every start."
		echo "You must also set the single variable named eula in it to true."
		echo "Otherwise the server will refuse to run entirely, and tell you why."
		sleep 5
		countdown 5
		echo "First run commencing..."
		java $fullarglist
		echo "The first run is now over! Please accept the EULA by editing the eula.txt file."
		echo "Then come back to this terminal and press any key to launch the server!"
		read -s -n 1
		echo "Welcome back! Starting server now..."
		test -f ./.running
		case $? in
			0*)
				running=1
				;;
			1*)
				running=0
				;;
		esac
		if [[ $running = 0 ]]; then
			touch ./.running
			java $fullarglist
			serverexit=$?
			rm ./.running
		else
			echo "The server is currently running, or has abruptly crashed."
			echo "This may happen if you close the terminal window whilst the server is running."
			echo "Please make a copy of your server folder, remove the .running file, and proceed."
			echo "If you don't run into any problems, you can delete the copy you just made."
			echo "Otherwise, locate the running instance using htop or some similar program."
			echo "This script will NOT proceed in an effort to prevent damage to the server."
			echo "If you are certain no other instance is running, please re-run this script."
			echo "However, before doing so, ensure the .running file no longer exists."
			echo "If it does exist, this script will think the server is running already."
			echo "When that happens, this warning message will appear when this script is ran."
			read -s -n 1 -p "Press any key to exit..."
		fi
	else
		echo "Welcome back! It seems this isn't the first run of this server."
		echo "Assuming the eula.txt file has already been edited to say true."
		echo "Starting server in 5..."
		sleep 1
		countdown 4
		touch ./.running
		java $fullarglist
		serverexit=$?
		rm ./.running
	fi
}


# These echo lines are to inform the user on how to prevent the server from being killed upon closing the terminal.
echo "Please make sure you're launching this in a detachable 'screen' session."
echo "If not, when you close this terminal, the server will IMMEDIATELY die."
echo "If that's fine with you, you may disregard this message."
echo "Otherwise, press ctrl+C before the upcoming countdown finishes."
echo "If you do not have the screen command available, you may need to install it."
echo "The steps to install screen may vary from ditribution to distribution."
echo "This script would get rather massive if I covered all of them, so I won't be."
echo "This script will continue in 15 seconds if you don't press ctrl+C."
sleep 10
countdown 5
server_start
after_server_exit
