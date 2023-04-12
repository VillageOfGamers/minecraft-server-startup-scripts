#!/bin/sh

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

# The screenwarn variable is just a quick toggle I built in to enable or disable the parent/child process relationship in Linux and other POSIX OSes.
# Set it to 0 here in order to disable the warning, or set it to 1 (which is the default) in order to enable the warning.
# I have the warning enabled by default on this script specifically so that those who need the nudge can understand what may happen.
# This mainly applies in the case of them running the script directly via an SSH or console terminal, resulting in the script and all children listening for SIGHUP.
# The screen utility and some direct alternatives hide any SIGHUP that comes from its parent process, and ignores it on its own as well, keeping the programs alive.
screenwarn=1

# The jarname variable specifies which file the Java runtime executes first. You generaly want this to be a RELATIVE path (i.e. "./server.jar" is a relative path).
# The -Xms#G argument specifies how much memory to allocate upon starting the Java instance.
# The -Xmx#G argument specifies the MAXIMUM amount of memory to allocate to the Java instance, NOT including overhead.
# The overhead you see on this will be around 256MB, give or take.

# I recommend leaving 1GB of RAM or more available if you are using Linux without a graphical environment.
# If you are using a desktop environment in Linux, leave 2GB of RAM or more available for the OS.
# This script is NOT usable in Windows; it is expressly designed with the Linux BASH shell in mind.
jarname="./server.jar"
arglist="-Xms8G -Xmx16G -jar $jarname"

# THESE VARIABLES ARE NOT TO BE TOUCHED UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING!
# These arguments for the Java instance have been hand-tuned by the Minecraft community to provide optimal performance of the server.
# The user-adjustable argument list is ABOVE these comment lines; those control how much RAM it can use, and the name of the JAR to launch.
gctuning="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
fullarglist="$gctuning $arglist"

# This olddir variable is to store the initial working directory this script got launched from.
# This is because the script DOES change which directory the shell uses if the serverdir variable above is NOT set to ./ per its default.
# Note: This does NOT mean the directory the FILE sits in, it means the path your SHELL'S current working directory was at the time this script got started.
olddir=$(pwd)

# This koops variable dictates whether or not the script will attempt to kill PID 1 (the init system) using SIGKILL.
# Killing PID 1 in such a manner will cause a kernel panic every single time, and without fail.
# However, in some scenarios, this is preferable to encountering OS corruption from more than just a bit-flip in a single file.
# As a result, I HIGHLY recommend leaving this variable set to 1.
# However, please keep in mind that if you have it set to 1, you ALSO need to grant the user that runs this script the ability to run sudo without password verification.
# This is so you don't have to store a plaintext password inside a script, eliminating a possible way that someone may be able to compromise your system.
# If you go that route in order to provide this script the capability to run kill -9 1 (which sends SIGKILL to init), ensure the user this runs as DOES NOT AUTOLOGIN EVER.
koops=0

# This function is just a wait loop, with the i variable getting set by whichever part of the script calls it.
# The i variable is the number of seconds to wait via this loop, while printing a countdown each second.
countdown () {
	i=$1
	while [ $i -gt 0 ]; do
		echo "$i..."
		i=$((i-1))
		sleep 1
	done
}

# This entire function is the full, unadulterated body that handles just about the entire process from start to end.
# This thing handles pulling the latest version of the server JAR you're using (if you set it up beforehand).
# It then proceeds to launch it, and perform several tiny checks to see what kind of environment it may or may not be in.
# One of these checks is whether the actual Minecraft server is in the directory you pointed it to try to go to.
# If it cannot find it there, it instead tries checking the initial directory the script started executing from.
# If both fail, the script will error out completely, however if it does find the server, regardless of where, it will continue.
# It will still warn you if it cannot find it in the directory you told it to go into, but it will continue to run just fine.

# These variables are here specifically to dictate the URL to pull the latest server JAR from.
# The top variable, dlenable, is the ACTUAL toggle flag for this script to pull the latest JAR from wherever.
# I have left this variable set to 0 so that it does NOT pull the latest JAR from anywhere, so that you can point it where YOU need it to be.
# I just so happen to have this file set to default to the PaperMC API at this point in time; not everyone in the world uses PaperMC, I get that.
# The only time you should ever need to change this URL format is if they ever change how the API works, or where you're getting your server JAR from.
# As of 4/12/2023, the server I have been writing and improving this script for is on version 1.19.4.
server_start () {
	download=0
	mcver="1.19.4"
	baseurl="https://api.papermc.io/v2/projects/paper/versions/"$mcver
	build="$(curl -sX GET "$baseurl"/builds -H 'accept: application/json' | jq '.builds [-1].build')"
	dlbuild=$baseurl"/builds/"$build"/downloads/paper-"$mcver"-"$build".jar"
	oldbuild=$(grep . ./.version)
	if [ $oldbuild = $build ] && [ $download = 1 ]; then
		dlenable=0
	else
		dlenable=1
	fi
	echo $build > ./.version
	if [ $dlenable = 1 ]; then
		echo "Downloading latest Paper server JAR file for version ${mcver}..."
		wget $dlbuild -O $jarname >/dev/null 2>&1
	fi
	touch ./.running
	lastexit=$?
	if [ $lastexit -gt 1 ]; then
		critical_stop
	elif [ $lastexit = 1 ]; then
		echo "[ERROR] Touch has run into an error. Could not create running file."
		echo "[ERROR] Please ensure this user account has WRITE access to path:"
		pwd
		echo "Press enter to exit..."
		read -r nil
		exit
	else
		java $fullarglist
		serverexit=$?
		rm ./.running
	fi
}

# This function is designed to catch any possible logic errors from programs whose exit codes are only either 0 or 1.
# This does not account for ALL commands, but it does account for quite a few used in this script, such as grep and test.
# Any program used in this script that does not have a simple 0/1 exit status based on context will have its own error catching.
# Please note that I do not have a gigantic list of what the exit codes to every single program used in this script could be.
# As a result this function is, again, ONLY meant for programs that are KNOWN to only ever exit with a 0 or 1; nothing else.
# Should this function ever trigger the part of the script it is meant to trigger, you will want to listen to its advice.
catch_error () {
	case $lastexit in
		0)
			error=0
		;;
		1)
			error=1
		;;
		2)
			if [ $cmd = "grep" ]; then error=2; else critical_stop; fi
		;;
		*)
			critical_stop
		;;
	esac
}

# This function is ONLY designed to trigger should any program used by the script refuse to adhere to its normal function.
# By that I don't mean trying to run ls / and getting error 2 as a normal user; THAT is expected.
# What I DO mean is, something like the test command exiting with anything higher than 1.
# Such an exit would immediately be concerning because test is a literal true/false program; it does nothing else at all.
critical_stop () {
	if [ $koops = 1 ]; then
		echo "[CRITICAL] SOMETHING WENT CATASTROPHICALLY WRONG WITH YOUR SYSTEM!"
		echo "[CRITICAL] THIS COMPUTER IS NOT FIT TO RUN ANY SIGNIFICANT LOAD AT ALL!"
		echo "[CRITICAL] CHECK YOUR CPU TEMPERATURE, AND TEST YOUR RAM AS WELL!"
		echo "[CRITICAL] HELL, AT THIS POINT, TEST EVERY SINGLE PART IN THE SYSTEM ON ITS OWN!"
		echo "[CRITICAL] IT IS NOT NORMAL AT ALL FOR THE TEST UTILITY TO PRODUCE A $lastexit EXIT CODE!"
		echo "[CRITICAL] THE FAILING COMMAND LITERALLY ONLY EVER RETURNS A 0 OR 1, THAT IS IT!"
		echo "[CRITICAL] FOR THIS COMMAND TO RETURN ANYTHING ELSE, A GRIEVOUS ERROR OCCURRED!"
		echo "[CRITICAL] THIS SCRIPT IS GOING TO COUNT DOWN FOR 60 SECONDS!"
		echo "[CRITICAL] AFTER THIS COUNTDOWN, THE SCRIPT WILL ATTEMPT TO SHUT DOWN YOUR PC!"
		echo "[CRITICAL] IT IS CRITICAL THAT YOU CHECK ALL- AND I MEAN ALL- OF ITS PARTS!"
		echo "[CRITICAL] YOUR MOST LIKELY ERROR IS JUST A CORRUPTED OPERATING SYSTEM DISK."
		echo "[CRITICAL] HOWEVER! I STILL HIGHLY RECOMMEND AND ENCOURAGE YOU TO INVESTIGATE!"
		echo "[CRITICAL] EITHER WAY, LEAVING THIS PC RUNNING IN ITS CURRENT STATE IS NOT SAFE!"
		echo "[CRITICAL] SENDING SIGKILL TO INIT IN 60 SECONDS! THIS WILL CAUSE A KERNEL PANIC!"
		echo "[CRITICAL] IF YOU REALLY WISH TO STOP THIS SHUTDOWN ATTEMPT, PRESS CTRL+C NOW!"
		sleep 45
		echo "[CRITICAL] YOU HAVE 15 SECONDS REMAINING TO STOP THIS SCRIPT FROM FORCING A PANIC!"
		countdown 15
		sudo kill -9 1
	else
		echo "[CRITICAL] SOMETHING WENT CATASTROPHICALLY WRONG WITH YOUR SYSTEM!"
		echo "[CRITICAL] THIS COMPUTER IS NOT FIT TO RUN ANY SIGNIFICANT LOAD AT ALL!"
		echo "[CRITICAL] CHECK YOUR CPU TEMPERATURE, AND TEST YOUR RAM AS WELL!"
		echo "[CRITICAL] HELL, AT THIS POINT, TEST EVERY SINGLE PART IN THE SYSTEM ON ITS OWN!"
		echo "[CRITICAL] IT IS NOT NORMAL AT ALL FOR THE TEST UTILITY TO PRODUCE A $lastexit EXIT CODE!"
		echo "[CRITICAL] THE FAILING COMMAND LITERALLY ONLY EVER RETURNS A 0 OR 1, THAT IS IT!"
		echo "[CRITICAL] FOR THIS COMMAND TO RETURN ANYTHING ELSE, A GRIEVOUS ERROR OCCURRED!"
		echo "[CRITICAL] SINCE THE 'koops' VARIABLE IS NOT SET, THIS SCRIPT WILL NOT KILL PID 1."
		echo "[CRITICAL] HOWEVER, I STILL HIGHLY RECOMMEND SHUTTING DOWN YOUR SYSTEM AS SOON AS POSSIBLE!"
		echo "[CRITICAL] THIS SYSTEM SHOULD NOT BE IN PRODUCTION USE BEYOND THIS POINT!"
		echo "[CRITICAL] THERE IS A VERY VALID REASON EVERY SINGLE ONE OF THESE LINES IS MARKED CRITICAL!"
		echo "[CRITICAL] THIS SCRIPT IS NOW GOING TO EXIT! I HIGHLY SUGGEST RUNNING 'sudo poweroff'!"
		echo "[CRITICAL] PLEASE PRESS ENTER TO EXIT AFTER YOU HAVE READ THIS TEXT IN ITS ENTIRETY!"
		read -r nil
		exit
	fi
}

# This small function is simply to ask the user if they wish to restart the Minecraft server.
# I have a catch-all case for key presses that are NOT a Y or N, which redirect the user through the question again.
# This is not meant to be an annoyance, but rather a simple way to make sure the user has properly chosen an answer.
ask_restart () {
	read -r restart
	case $restart in
		y*)
			echo "Beginning restart procedure. Skipping warning about closing running shell."
			server_start
			invalid=0
		;;
		n*)
			echo "Thank you for using Giantvince1's Minecraft server startup automater!"
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
	read -r changes
	case $changes in
		y*)
			if [ $loopcounter -gt 1 ]; then
				echo "Since you plan on changing things, this script will not loop again."
			else
				echo "Since you plan on changing things, this script will not loop."
			fi
			echo "Once you finish editing the variables, please restart the script manually."
			echo "Press enter to exit..."
			read -r nil
			invalid=0
			exit
		;;
		n*)
			if [ $loopcounter -gt 1 ]; then
				echo "Since you don't plan on changing anything, the script is able to loop again."
			else
				echo "Since you don't plan on changing anything, the script is able to loop."
			fi
			echo "This is by design; this script is capable of re-using itself infinitely."
			echo "It will also only do so each time the user WANTS it to. It will not forkbomb."
			echo "Would you like to restart the Minecraft server? (Y/N)"
			invalid=0
			ask_restart
			while [ $invalid = 1 ]; do
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
	while [ $serverexit = 0 ]; do
		echo "The server has been shut down. Do you wish to change any variables? (Y/N)"
		ask_modify
	done
	echo "The server has encountered some sort of error. Please check the console logs."
	echo "This script will NOT be offering you the ability to restart the server."
	echo "I recommend you look through the server logs and look for errors."
	echo "This script will exit, however you may still read the server console log."
	echo "This script exiting itself should not close the terminal window."
	echo "However, in case that were to happen, there is a failsafe in this script."
	echo "Press enter to exit..."
	read -r nil
}

# This gigantic function is what handles all the pre-start checks for the Minecraft server.
# It also handles most of the user interaction before it actually launches the server itself.
# Unless you are adept at reading and writing BASH scripts, I HIGHLY recommend not touching this!
# You may change the text inside the echo commands, but I recommend you keep their meaning similar!
# You may easily confuse someone using your modified version of this script.
# The echo commands provide useful information to the end user based on the conditions the checks find.
start_function () {
	loopcounter=$((loopcounter+1))
	if [ $serverdir = ./ ]; then
		test -f $jarname
		lastexit=$?
		catch_error
		notfound=$error
		invalidpath=$error
	else
		cd $serverdir && test -f $jarname
		lastexit=$?
		catch_error
		invalidpath=$error
		cd "$olddir" && test -f $jarname
		lastexit=$?
		catch_error
		notfound=$error
	fi
	if [ $invalidpath = 0 ] && [ $notfound = 0 ]; then
		test -f ./eula.txt
		lastexit=$?
		catch_error
		firstrun=$error
	elif [ $invalidpath = 1 ] && [ $notfound = 0 ]; then
		echo "[WARN] This script could locate your Minecraft server."
		echo "[WARN] However, it found the server where you started the script from."
		echo "[WARN] This should not be intentional. Printing current variables..."
		echo "[WARN] Please set the serverdir variable to the correct path."
		echo "serverdir: $serverdir"
		echo "olddir: $olddir"
		echo "jarname: $jarname"
		echo "arglist: $arglist"
		echo "Press ctrl+C now if you wish to fix the issue, or press enter to continue."
		read -r nil
		echo "Continuing execution..."
		test -f ./eula.txt
		lastexit=$?
		catch_error
		firstrun=$error
	else
		echo "[ERROR] This script cannot locate your Minecraft server!"
		echo "[ERROR] Printing current script variables so the issue may be found..."
		echo "serverdir: $serverdir"
		echo "olddir: $olddir"
		echo "jarname: $jarname"
		echo "arglist: $arglist"
		echo "Please ensure these variables are correct, and modify them accordingly."
		echo "Press enter to exit..."
		read -r nil
		exit
	fi
	if [ $firstrun = 1 ]; then
		echo "Welcome to the Minecraft community, and your new Minecraft server!"
		echo "You will be required to accept the EULA in order to run the server."
		echo "The server will run in the next 10 seconds so the EULA file can be generated."
		echo "Do not delete the eula.txt file, as the server checks for it on every start."
		echo "You must also set the single variable named eula in it to true."
		echo "Otherwise the server will refuse to run entirely, and tell you why."
		sleep 5
		countdown 5
		echo "First run commencing..."
		server_start
		echo "The first run is now over! Please accept the EULA by editing the eula.txt file."
		echo "Then come back to this terminal and press any key to launch the server!"
		read -r nil
		echo "Welcome back! Starting server now..."
		test -f ./.running
		lastexit=$?
		catch_error
		case $error in
			0)
				running=1
				;;
			1)
				running=0
				;;
		esac
		if [ $running = 0 ]; then
			server_start
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
			echo "Press enter to exit..."
			read -r nil
		fi
	else
		echo "Welcome back! It seems this isn't the first run of this server."
		echo "Checking that the eula.txt file has already been edited to say true..."
		grep true ./eula.txt
		lastexit=$?
		cmd="grep"
		catch_error
		noeula=$error
		if [ $noeula = 0 ]; then
			echo "Starting server in 3 seconds."
			countdown 3
			server_start
		else
			echo "The EULA file has not been edited to say true."
			echo "This file MUST be edited to contain 'eula=true' on its own line."
			echo "Please edit the file eula.txt located in the following directory:"
			pwd
			echo "After you've made the needed change, you may come back to this terminal."
			ask_restart
		fi
	fi
}

script_init () {
# These echo lines are to inform the user on how to prevent the server from being killed upon closing the terminal.
# You can disable the warning if you wish via the screenwarn variable at the top of this script. Just set it to 0.
	if [ $screenwarn = 1 ]; then
		echo "Please make sure you're launching this in a detachable 'screen' session."
		echo "If not, when you close this terminal, the server will IMMEDIATELY die."
		echo "If that's fine with you or you've prepared, you may disregard this message."
		echo "Otherwise, press ctrl+C before the upcoming countdown finishes."
		echo "If you do not have the screen command available, you may need to install it."
		echo "The steps to install screen may vary from ditribution to distribution."
		echo "This script would get rather massive if I covered all of them, so I won't be."
		echo "This script will continue in 15 seconds if you don't press ctrl+C."
		countdown 15
	else
		echo "Warning regarding parent/child process relations in Linux disabled."
		echo "Executing main body of script..."
	fi
	start_function
	after_server_exit
}
script_init
