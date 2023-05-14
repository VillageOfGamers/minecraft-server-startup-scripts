#!/bin/sh
# shellcheck disable=SC2164,SC2086,SC2027,SC2269,SC2034,SC2181

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

# The screenwarn variable is just a quick toggle I built in to enable or disable the parent/child process relationship in Linux and other POSIX OSes.
# Set it to 0 here in order to disable the warning, or set it to 1 (which is the default) in order to enable the warning.
# I have the warning enabled by default on this script specifically so that those who need the nudge can understand what may happen.
# This mainly applies in the case of them running the script directly via an SSH or console terminal, resulting in the script and all children listening for SIGHUP.
# The screen utility and some direct alternatives hide any SIGHUP that comes from its parent process, and ignores it on its own as well, keeping the programs alive.
screenwarn=1

# This koops variable dictates whether or not the script will attempt to kill PID 1 (the init system) using SIGKILL.
# Killing PID 1 in such a manner will cause a kernel panic every single time, and without fail.
# However, in some scenarios, this is preferable to encountering OS corruption from more than just a bit-flip in a single file.
# As a result, I HIGHLY recommend leaving this variable set to 1.
# However, please keep in mind that if you have it set to 1, you ALSO need to grant the user that runs this script the ability to run sudo without password verification.
# This is so you don't have to store a plaintext password inside a script, eliminating a possible way that someone may be able to compromise your system.
# If you go that route in order to provide this script the capability to run kill -9 1 (which sends SIGKILL to init), ensure the user this runs as DOES NOT AUTOLOGIN EVER.
koops=0

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
arglist="-Xms16G -Xmx16G -jar $jarname"

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

base_dl_checks () {
	mcver="1.19.4"
	baseurl="https://api.papermc.io/v2/projects/paper/versions/"$mcver
	build="$(curl -sX GET "$baseurl"/builds -H 'accept: application/json' | jq '.builds [-1].build')"
	dlbuild=$baseurl"/builds/"$build"/downloads/paper-"$mcver"-"$build".jar"
	oldbuild=$(grep . ./.version)
}

# This function is just a wait loop, with the i variable getting set by whichever part of the script calls it.
# The i variable is the number of seconds to wait via this loop, while printing a countdown each second.
countdown () {
	i=$1
	while [ $i -gt 0 ]; do
		echo $i"..."
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
	if [ $download = 1 ]; then
		base_dl_checks
		if [ $oldbuild != $build ]; then
			echo "Download mode enabled. This script will replace the old one with the new one."
			echo "Do you wish to continue with the attempt to download the latest version? (Y/N)"
			read -r keepdl
			case $keepdl in
				n*)
					echo "Download mode disabled by user choice. Halting download of new version."
					invalid=0
				;;
				y*)
					echo "Download mode confirmed by user. Continuing with download of latest JAR."
					wget $dlbuild -O $jarname > /dev/null 2>&1
					if [ $? = 0 ]; then
						echo "Download of latest server version successful. Proceeding with launch."
						echo $build > ./.version
					else
						echo "Download of latest version failed. This script cannot continue from here."
						echo "Please double-check the download-related variables are correct in the script."
						echo "Please replace "$jarname" with a valid copy, then re-execute this script."
						echo "If you do not want to enable download mode, then set the download variable to 0."
						echo "This script will now exit."
						exit 2
					fi
					invalid=0
				;;
				*)
					echo "Invalid choice. Your choices are yes (Y) or no (N)."
					invalid=1
				;;
			esac
		else
			echo "Download mode enabled. "$jarname" also has no new releases at this time."
			echo "Disabling download mode for this run only due to the lack of difference."
		fi
	else
		echo "Download mode disabled. "$jarname" will remain at its current version."
		echo "All logic surrounding the support of downloading a new version is off."
		echo "This means no related variables are set, and no related files will be modified."
	fi
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
		*)
			critical_stop
		;;
	esac
	touch ./.running
	lastexit=$?
	catch_error
	if [ $error = 1 ]; then
		echo "[ERROR] Touch has run into an error. Could not create running file!"
		echo "[ERROR] Please ensure this user account has WRITE access to path:"
		pwd
		echo "This script will now exit."
		exit 2
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
# grep is another example; it only returns a 0, 1, or 2 depending on the reason for failure, or if it succeeded.
# This is why, just in case grep ever does fail with 2, this script will NOT try to send SIGKILL to PID 1.
# This script is only testing after runs of the "test" utility and "grep" utility, it doesn't test for other items at this time.
# Even then, it's impossible to know if this section can take care of the error if such an error DOES occur.
# This is because, if the test utility does happen to raise a known bogus error, this portion may not recognize the bogus error.
# This would be due to the fact that "[" (yes, that bracket just left of this text) is also the "test" utility.
# Some systems symlink the two together, however others may have actual separate files for each. They both do the exact same thing.
critical_stop () {
	echo "[FATAL] SOMETHING WENT CATASTROPHICALLY WRONG WITH YOUR SYSTEM!"
	echo "[FATAL] THIS COMPUTER IS NOT FIT TO RUN ANY SIGNIFICANT LOAD AT ALL!"
	echo "[FATAL] CHECK YOUR CPU TEMPERATURE, AND TEST YOUR RAM AS WELL!"
	echo "[FATAL] HELL, AT THIS POINT, TEST EVERY SINGLE PART IN THE SYSTEM ON ITS OWN!"
	echo "[FATAL] IT IS NOT NORMAL AT ALL FOR THE LAST COMMAND TO PRODUCE A $lastexit EXIT CODE!"
	echo "[FATAL] THE FAILING COMMAND LITERALLY ONLY EVER RETURNS A 0, 1, OR 2!"
	echo "[FATAL] FOR THIS COMMAND TO RETURN ANYTHING ELSE, A GRIEVOUS ERROR OCCURRED!"
		if [ $koops = 1 ]; then
		echo "[FATAL] THIS SCRIPT IS GOING TO COUNT DOWN FOR 60 SECONDS!"
		echo "[FATAL] AFTER THIS COUNTDOWN, THE SCRIPT WILL ATTEMPT TO SHUT DOWN YOUR PC!"
		echo "[FATAL] IT IS CRITICAL THAT YOU CHECK ALL- AND I MEAN ALL- OF ITS PARTS!"
		echo "[FATAL] YOUR MOST LIKELY ERROR IS JUST A CORRUPTED OPERATING SYSTEM DISK."
		echo "[FATAL] HOWEVER! I STILL HIGHLY RECOMMEND AND ENCOURAGE YOU TO INVESTIGATE!"
		echo "[FATAL] EITHER WAY, LEAVING THIS PC RUNNING IN ITS CURRENT STATE IS NOT SAFE!"
		echo "[FATAL] SENDING SIGKILL TO INIT IN 60 SECONDS! THIS WILL CAUSE A KERNEL PANIC!"
		echo "[FATAL] IF YOU REALLY WISH TO STOP THIS SHUTDOWN ATTEMPT, PRESS CTRL+C NOW!"
		sleep 45
		echo "[FATAL] YOU HAVE 15 SECONDS REMAINING TO STOP THIS SCRIPT FROM FORCING A PANIC!"
		countdown 15
		sudo kill -9 1
	else
		echo "[FATAL] SINCE THE 'koops' VARIABLE IS NOT SET, THIS SCRIPT WILL NOT SIGKILL PID 1."
		echo "[FATAL] HOWEVER, I STILL HIGHLY RECOMMEND SHUTTING DOWN YOUR SYSTEM AS SOON AS POSSIBLE!"
		echo "[FATAL] THIS SYSTEM SHOULD NOT BE IN PRODUCTION USE BEYOND THIS POINT!"
		echo "[FATAL] THERE IS A VERY VALID REASON EVERY SINGLE ONE OF THESE LINES IS MARKED CRITICAL!"
		echo "[FATAL] THIS SCRIPT IS NOW GOING TO EXIT! I HIGHLY SUGGEST RUNNING 'sudo poweroff'!"
		exit 3
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
			echo "We hope to see you soon! Exiting script now."
			exit 1
		;;
		*)
			echo "Invalid choice. Your choices are yes (Y) or no (N)."
			invalid=1
		;;
	esac
}

# This function is designed to query, under specific circumstances, if the user wishes to create a fresh Minecraft server.
# This function will only be called if at least one of these conditions are met (one per line):
# a) no Minecraft server is found in $serverdir, but one was found in $olddir, and $serverdir is not ./;
# b) no Minecraft server is found at all, in either $serverdir or $olddir
# Any condition which results in this script thinking there is a valid server at $serverdir will prevent this function entirely.
# This is mainly via a check to ensure the path is browsable, and a file named $jarfile exists in the directory.
newserver () {
	read -r newserver
	case $newserver in
		y*)
			echo "Okay, a NEW Minecraft server instance will be started within the folder:"
			pwd
			echo "If this is NOT desired, you will have 10 seconds to press CTRL+C."
			echo "This will give you time to stop the attempt before the download begins."
			countdown 10
			echo "No CTRL+C received, continuing new instance setup..."
			invalid=0
		;;
		n*)
			echo "Per your request, this server will NOT be attempting to start a new server."
			echo "This script will now exit as there is no valid server to start up with."
			invalid=0
			exit 1
		;;
		*)
			echo "[WARN] Invalid choice. Your options are yes (Y) or no (N)."
			invalid=1
		;;
	esac
}

# This function is here in case $serverdir is NOT ./ and BOTH $serverdir AND $olddir do NOT contain a valid server.
# This is purely for the case where one wants to start a new server, but 2 known paths can be chosen, and neither has a valid server.
# That is ALL this function does, is gather that answer, and act based on the answer.
whichpath () {
	read -r whichpath
	case $whichpath in
		o*)
			echo "You have chosen the old directory. Changing to directory and printing path..."
			echo "Current path: "$olddir
			cd $olddir
			echo "Would you like to truly start a new server here in this path? (Y/N)"
			invalid=0
			newserver
			while [ $invalid = 1 ]; do
				newserver
			done
		;;
		n*)
			echo "You have chosen the new directory. Changing to directory and printing path..."
			echo "Current path: "$serverdir
			cd $serverdir
			echo "Would you like to truly start a new server here in this path? (Y/N)"
			invalid=0
			newserver
			while [ $invalid = 1 ]; do
				newserver
			done
		;;
		*)
			echo "Invalid choice. Your choices are old (O) or new (N)."
			invalid=1
		;;
	esac
}

# This function is designed to ask whether to try to create the path to a specified server directory.
# Please note this script can only operate under the context of the user you run it as yourself!
# This means any path entered into the $serverdir variable MUST be accessible by the current user!
# If it is not currently a path that exists, then the final existing directory leading to it MUST be WRITABLE by the user!
createpath () {
	read -r createpath
	case $createpath in
		y*)
			echo "Attempting to start up and initialize NEW server instance..."
			invalid=0
			mkdir -p $serverdir
			lastexit=$?
			catch_error
			inaccessible=$error
			if [ $inaccessible = 1 ]; then
				echo "[ERROR] Unable to create path to the specified directory!"
				echo "[ERROR] Specified path: "$serverdir
				echo "[ERROR] The only path I can access directly is the location I was started at!"
				echo "[ERROR] Since I am unable to start a server which I cannot access,"
				echo "[ERROR] and you, the user, have specified to try the specified path anyway,"
				echo "[ERROR] I am NOT going to go to my starting path and start the one that lives there."
				echo "[ERROR] This script is now going to exit."
				exit 2
			else
				cd $serverdir
				echo "The specified path was successfully created, and your user has write access!"
				echo "Current directory: "$serverdir
				echo "Old directory: "$olddir
				echo "Continuing with startup script execution..."
				echo "Do you wish to start a NEW Minecraft server instance in this directory? (Y/N)"
				newserver
				while [ $invalid = 1 ]; do
					newserver
				done
			fi
		;;
		n*)
			echo "Download mode has been disabled for THIS RUN per user request."
			echo "Please edit the serverdir variable and/or the download variable."
			echo "Now changing directory back to: "$olddir
			cd $olddir
			echo "Now continuing script execution from the old directory..."
			invalid=0
		;;
		*)
			echo "[WARN] Invalid choice. Your options are yes (Y) or no (N)."
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
			echo "This script is now going to exit to allow you to modify its variables."
			invalid=0
			exit 0
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
	if [ $serverexit = 0 ]; then
		echo "The server has been shut down. Do you wish to change any variables? (Y/N)"
		ask_modify
		while [ $invalid = 1 ]; do
			ask_modify
		done
	else
		echo "The server has encountered some sort of error. Please check the console logs."
		echo "This script will NOT be offering you the ability to restart the server."
		echo "I recommend you look through the server logs and look for errors."
		echo "This script will exit, however you may still read the server console log."
		exit 2
	fi
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
		cd $serverdir
		lastexit=$?
		catch_error
		inaccessible=$error
		if [ $inaccessible = 0 ]; then
			test -f $jarname
			lastexit=$?
			catch_error
			invalidpath=$error
		fi
		cd $olddir && test -f $jarname
		lastexit=$?
		catch_error
		notfound=$error
	fi
	if [ $invalidpath = 0 ]; then
		test -f ./eula.txt
		lastexit=$?
		catch_error
		firstrun=$error
	elif [ $invalidpath = 1 ] && [ $notfound = 0 ]; then
		echo "[WARN] This script could locate your Minecraft server."
		echo "[WARN] However, it found the server where you started the script from."
		echo "[WARN] This should not be intentional. Printing current variables..."
		echo "[WARN] Please ensure the following variables are all correct:"
		echo "serverdir: "$serverdir
		echo "olddir: "$olddir
		echo "jarname: "$jarname
		echo "arglist: "$arglist
		echo "[WARN] Press ctrl+C now if you wish to fix the issue, or press enter to continue."
		read -r nil
		if [ $download = 1 ]; then
			if [ $inaccessible = 1 ]; then
				echo "[WARN] The specified server directory is currently inaccessible to this user."
				echo "[WARN] Please double-check you have specified the right path to locate the server."
				echo "Specified path: "$serverdir
				echo "Do you want this script to create this path for you, if able? (Y/N)"
				echo "Please be aware that a valid server already does exist."
				echo "Existing server path: "$olddir
				echo "If you wish to run the server already available, please answer no here."
				createpath
				while [ $invalid = 1 ]; do
					createpath
				done
			else
				cd $serverdir
				echo "[WARN] This script is capable of navigating to the specified path."
				echo "[WARN] However, said path does NOT currently hold a Minecraft server."
				echo "[WARN] Please double-check that the download and serverdir variables are of your choosing."
				echo "Specified path: "$serverdir
				echo "Do you wish to start a NEW Minecraft server instance in this directory? (Y/N)"
				newserver
				while [ $invalid = 1 ]; do
					newserver
				done
			fi
		else
			echo "[WARN] This script has Download Mode disabled at this time."
			echo "[WARN] Since it is disabled, I cannot proceed with starting a new server from scratch."
			echo "[WARN] However, I did find an existing server on this machine!"
			echo "User-specified path: "$serverdir
			echo "Current working path: "$olddir
			echo "Changing path to the old directory and continuing script execution..."
			cd $olddir
		fi
		test -f ./eula.txt
		lastexit=$?
		catch_error
		firstrun=$error
	else
		if [ $download = 1 ]; then
			if [ $serverdir = ./ ]; then
				echo "Download Mode is currently enabled. Downloading latest server jar to path:"
				pwd
				echo "Current server JAR name: "$jarname
				echo "Do you wish to start a new server in the above folder? (Y/N)"
				newserver
				while [ $invalid = 1 ]; do
					newserver
				done
			else
				echo "[WARN] This script cannot locate your Minecraft server!"
				echo "[WARN] Printing current script variables so the issue may be found..."
				echo "serverdir: "$serverdir
				echo "olddir: "$olddir
				echo "jarname: "$jarname
				echo "arglist: "$arglist
				if [ $inaccessible = 1 ]; then
					echo "Would you like me to try to create a path to your specified directory? (Y/N)"
					echo "Specified path: "$serverdir
					createpath
					while [ $invalid = 1 ]; do
						createpath
					done
				else
					echo "I am able to traverse into the path you have specified previously."
					echo "However neither that path nor where this script was ran from have a valid server."
					echo "Which path did you intend for me to use for a Minecraft server? (O/N) [O=old,N=new]"
					whichpath
					while [ $invalid = 1 ]; do
						whichpath
					done
				fi
			fi
		else
			echo "Download Mode is disabled globally in the script. Cannot download server JAR file."
			echo "Also, no valid server exists based on the settings of this script."
			echo "Printing variables so any possible issues may be found..."
			echo "serverdir: "$serverdir
			echo "olddir: "$olddir
			echo "jarname: "$jarname
		fi
	fi
	if [ $firstrun = 1 ]; then
		echo "Welcome to the Minecraft community, and your new Minecraft server!"
		echo "You will be required to accept the EULA in order to run the server."
		echo "The server will run in the next 10 seconds so the EULA file can be generated."
		echo "Do not delete the eula.txt file, as the server checks for it on every start."
		echo "You must also set the single variable named eula in it to true."
		echo "Otherwise the server will refuse to run entirely, and tell you why."
		countdown 10
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
			echo "Exiting script..."
			exit 2
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
			echo "This script will exit. Please restart it manually after you make the needed change."
			exit 2
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
