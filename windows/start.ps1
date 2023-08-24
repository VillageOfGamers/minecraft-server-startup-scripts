# Please set this variable based on whether or not you are running this script in an interactive mode.
# By interactive, I mean you, or another human, is interacting DIRECTLY with the script!
# If a human is NOT what is interacting with this script, then MAKE SURE TO REPLACE TRUE WITH FALSE!
$interactive=$true

# This variable directly specifies whether or not to enable the script's Download Mode logic.
# If this variable is set to $false, this script will NOT check for or download new server JAR releases.
# This also means that this script CANNOT ask to re-enable this function if it is disabled here!
# However, if this toggle is enabled, as per default, you MAY disable it via prompts during execution.
# All of those prompts will ONLY disable Download Mode on a PER-RUN BASIS however! It will NOT be permanent!
$download=$true

# This is the path to the server itself. I recommend having this be an absolute path.
# The reason I have it showing ".\" is to point it to the "current" directory.
# This means it will evaluate the server to be located inside the directory you get if you run pwd just before this script.
# This is a sensible default, as the script is designed to check if the variable is the default.
# If this variable is not the default, the script has a check in place to see if the initial working directory actually holds the server.
# The script will complain to you if that happens and this variable is not ".\", but it will allow you to continue still.
$serverdir=".\"

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
$jarname="./server.jar"
$arglist="-Xms4G -Xmx4G -jar $jarname"

# THESE VARIABLES ARE NOT TO BE TOUCHED UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING!
# These arguments for the Java instance have been hand-tuned by the Minecraft community to provide optimal performance of the server.
# The user-adjustable argument list is ABOVE these comment lines; those control how much RAM it can use, and the name of the JAR to launch.
$gctuningbig="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
$gctuningsmall="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"

# If you are using this to start a Minecraft server with LESS THAN 12GB OF RAM, please use gctuningsmall instead of gctuningbig.
# gctuningsmall is set up so that the server doesn't get starved of RAM on lower RAM allocation, and is beneficial for a low-RAM system.
$fullarglist="$gctuningsmall $arglist"

# This olddir variable is to store the initial working directory this script got launched from.
# This is because the script DOES change which directory the shell uses if the serverdir variable above is NOT set to ./ per its default.
# Note: This does NOT mean the directory the FILE sits in, it means the path your SHELL'S current working directory was at the time this script got started.
$olddir = Get-Location

# These variables are here specifically to dictate the URL to pull the latest server JAR from.
# I just so happen to have this file set to default to the PaperMC API at this point in time; not everyone in the world uses PaperMC, I get that.
# The only time you should ever need to change this URL format is if they ever change how the API works, or where you're getting your server JAR from.
# As of 8/23/2023, the server I have been writing and improving this script for is on version 1.20.1.
function basedlchecks {
	$mcver="1.20.1"
	$baseurl="https://api.papermc.io/v2/projects/paper/versions/$mcver"
	$getbuilds=Invoke-RestMethod "$baseurl/builds/"
	$build=$getbuilds.builds[-1]
	$buildinfo=Invoke-RestMethod "$baseurl/builds/$build"
	$remotename=$buildinfo.downloads.application.name
	$oldbuild=$(Select-String . .\.version)
}

if ($interactive -eq 1) {
	# This function is just a wait loop, with the i variable getting set by whichever part of the script calls it.
	# The i variable is the number of seconds to wait via this loop, while printing a countdown each second.
	function countdown {
		$i=$1
		while ($i -gt 0) {
			Write-Output "$i..."
			$i=$i-1
			Start-Sleep -Seconds 1
		}
	}
	# This entire function is the full, unadulterated body that handles just about the entire process from start to end.
	# This thing handles pulling the latest version of the server JAR you're using (if you set it up beforehand).
	# It then proceeds to launch it, and perform several tiny checks to see what kind of environment it may or may not be in.
	# One of these checks is whether the actual Minecraft server is in the directory you pointed it to try to go to.
	# If it cannot find it there, it instead tries checking the initial directory the script started executing from.
	# If both fail, the script will error out completely, however if it does find the server, regardless of where, it will continue.
	# It will still warn you if it cannot find it in the directory you told it to go into, but it will continue to run just fine.
	function serverstart {
		if ($download -eq $true) {
			basedlchecks
			if ($oldbuild -ne $build) {
				Write-Output "Download mode enabled. This script will replace the old JAR with the new one."
				Write-Output "Do you wish to continue with the attempt to download the latest version? (Y/N)"
				$key=$Host.UI.RawUI.ReadKey()
				$keepdl=$key.Character
				function keepdl {
					Switch ($keepdl) {
						Y {
							Write-Output "Download mode confirmed by user. Continuing with download of latest JAR."
							$response=Invoke-WebRequest "$baseurl/builds/$build/downloads/$remotename" -OutFile ".new_server.jar"
							$status=$response | Select-Object -Expand StatusCode
							if ($status -ge 200 -and $status -le 299 -and $status -ne 218) {
								Write-Output "Download of latest server version successful. Proceeding with launch."
								Write-Output $build > .\.version
								Remove-Item -Path $jarname
								Move-Item -Path ".new_server.jar" -Destination "$jarname"
							}
							else {
								Write-Output "Download of latest version failed. However this script can continue."
								Write-Output "The download was attempted and did fail."
								Write-Output "However the filename used was '.new_server.jar', not $jarfile."
								Write-Output "Because of this sanity check, the known good JAR is still available to use."
								Write-Output "Would you like to use the last known good JAR and continue to start the server? (Y/N)"
								$key=$Host.UI.RawUI.ReadKey()
								$continue=$key.Character
								function useoldjar {
									Switch ($continue) {
									Y {
										Write-Output "You have chosen to continue using the last known good JAR."
										Write-Output "This script will now delete the failed download and continue execution."
										Remove-Item -Path .\.new_server.jar
									}
									N {
										Write-Output "You have chosen to exit upon failure to download the new build."
										Write-Output "This script will now exit. If the download failure persists,"
										Write-Output "please double-check the download variables, or disable download mode."
										Write-Output "You may do so by setting the download variable near the top of this script to 0."
										exit 1
									}
									Default {
										Write-Output "Invalid choice. Your choices are yes (Y) or no (N)."
										useoldjar
									}
								}
							}
							useoldjar
						}
					}
						N {$keepdl=$false}
						Default {
							Write-Output "Invalid choice. Your choices are yes (Y) or no (N)."
							keepdl
						}
					}
				}
				keepdl
				if ($keepdl -eq $true) {
					
				}
			}
			else {
				Write-Output "Download mode enabled. $jarname also has no new releases at this time."
				Write-Output "Disabling download mode for this run only due to the lack of difference."
			}
		}
		else {
			Write-Output "Download mode disabled. $jarname will remain at its current version."
			Write-Output "All logic surrounding the support of downloading a new version is off."
			Write-Output "This means no related variables are set, and no related files will be modified."
		}
		$running=Test-Path -Type Leaf .\.running
		if ($running -eq $true) {
			Write-Output "[ERROR] The server has run into a crash at some point, or is running."
			Write-Output "[ERROR] Please fix the issue, and get rid of the .running file to proceed."
			Write-Output "[ERROR] This script will now exit due to the running condition..."
			exit 2
		}
		New-Item .\.running
		$denied=$LASTEXITCODE
		if ($denied -gt 0) {
			Write-Output "[ERROR] Touch has run into an error. Could not create running file!"
			Write-Output "[ERROR] Please ensure this user accont has WRITE access to path:"
			Get-Location | Select-Object -Expand Path | Write-Output
			Write-Output "Please press any key to exit. I cannot continue without WRITE access."
			$Host.UI.RawUI.ReadKey()
			exit 2
		}
		else {
			java.exe $fullarglist
			$serverexit=$LASTEXITCODE
			Remove-Item .\.running
		}
	}
	function askrestart {
		Write-Output "Would you like to restart the Minecraft server? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$restart=$key.Character
		Switch ($restart) {
			Y {
				Write-Output "The server will restart at your request."
				serverstart
			}
			N {
				Write-Output "Thank you for using Giantvince1's Minecraft server startup automater!"
				Write-Output "We hope to see you soon! Exiting script now."
				exit 0
			}
			Default {
				Write-Output "Invalid choice. Your choices are yes (Y) or no (N)."
				askrestart
			}
		}
	}
	function newserver {
		Write-Output "Would you like to truly start a new server here in this path? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$newserver=$key.Character
		Switch ($newserver) {
			Y {
				Write-Output "Okay, a NEW Minecraft server instance will be started within the folder:"
				Get-Location | Select-Object -Expand Path | Write-Output
				Write-Output "If this is NOT desired, you will have 10 seconds to press CTRL+C."
				Write-Output "This will give you time to stop the attempt before the download begins."
				countdown 10
				Write-Output "No CTRL+C received, continuing new instance setup..."
			}
			N {
				Write-Output "Per your request, this script will NOT be attempting to start a new server."
				Write-Output "This script will now exit as there is no valid server to start up with."
				exit 1
			}
			Default {
				Write-Output "[WARN] Invalid choice. Your options are yes (Y) or no (N)."
				newserver
			}
		}
	}
	function whichpath {
		Write-Output "I am able to traverse into the path you have specified previously."
		Write-Output "However neither that path nor where this script was ran from have a valid server."
		Write-Output "Which path did you intend for me to use for a Minecraft server? (O/N) [O=old,N=new]"
		$key=$Host.UI.RawUI.ReadKey()
		$whichpath=$key.Character
		Switch ($whichpath) {
			O {
				Write-Output "You have chosen the old directory. Changing to directory and printing path..."
				Write-Output "Current path: $olddir"
				Set-Location $olddir
				newserver
			}
			N {
				Write-Output "You have chosen the new directory. Changing to directory and printing path..."
				Write-Output "Current path: $serverdir"
				Set-Location $serverdir
				newserver
			}
			Default {
				Write-Output "Invalid choice. Your choices are old (O) or new (N)."
				whichpath
			}
		}
	}
	function createpath {
		
		Write-Output "Do you want this script to create this path for you, if able? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$createpath=$key.Character
		Switch ($createpath) {
			Y {
				Write-Output "Attempting to start up and initialize NEW server instance..."
				New-Item -Type Directory -Force $serverdir
				$accessible=$?
				if ($accessible -eq $true) {
					Set-Location $serverdir
					Write-Output "The specified path was successfully created, and your user has write access!"
					Write-Output "Current directory: $serverdir"
					Write-Output "Old directory: $olddir"
					Write-Output "Continuing with startup script execution..."
					newserver
				}
				else {
					Write-Output "[ERROR] Unable to create path to the specified directory!"
					Write-Output "[ERROR] Specified path: $serverdir"
					Write-Output "[ERROR] The only path I can access directly is the location I was started at!"
					Write-Output "[ERROR] Since I am unable to start a server which I cannot access,"
					Write-Output "[ERROR] and you, the user, have specified to try the specified path anyway,"
					Write-Output "[ERROR] I am NOT going to go to my starting path and start the one that lives there."
					Write-Output "[ERROR] This script is now going to exit."
					exit 1
				}
			}
			N {
				Write-Output "You have told me NOT to make a new directory."
				Write-Output "Directory in use: $olddir"
				Write-Output "Please double-check the serverdir variable in this script!"
				Write-Output "Continuing execution inside the old directory..."
				Set-Location $olddir
			}
			Default {
				Write-Output "Invalid choice. Your options are yes (Y) or no (N)."
				createpath
			}
		}
	}
	function askmodify {
		Write-Output "The server has been shut down. Do you wish to change any variables? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$changes=$key.Character
		Switch ($changes) {
			Y {
				if ($loopcounter -gt 1) {
					Write-Output "Since you plan on changing things, this script will not loop again."
				}
				else {
					Write-Output "Since you plan on changing things, this script will not loop."
				}
				Write-Output "Once you finish editing the variables, please restart the script manually."
				Write-Output "This script is now going to exit to allow you to modify its variables."
				Write-Output "Please press any key to continue..."
				$Host.UI.RawUI.ReadKey()
				exit 0
			}
			N {
				if ($loopcounter -gt 1) {
					Write-Output "Since you don't plan on changing anything, this script is able to loop again."
				}
				else {
					Write-Output "Since you don't plan on changing anything, this script is able to loop."
				}
				Write-Output "This is by design; this script is capable of re-using itself infinitely."
				Write-Output "It wil also only do so each time the user WANTS it to. It will not forkbomb."
				askrestart
			}
			Default {
				Write-Output "Invalid choice. Your choices are yes (Y) or no (N)."
				askmodify
			}
		}
	}
	function afterserverexit {
		if ($serverexit -eq 0) {
			askmodify
		}
		else {
			Write-Output "The server has encountered some sort of error. Please check the console logs."
			Write-Output "This script will NOT be offering you the ability to restart the server."
			Write-Output "I recommend you look through the server logs and look for errors."
			Write-Output "This script will not exit so that you may still read the server console log."
			Write-Output "Please press any key to exit..."
			$Host.UI.RawUI.ReadKey()
			exit 2
		}
	}
	function realstart {
		$loopcounter=$loopcounter+1
		if ($serverdir -eq ".\") {
			$validpath=Test-Path -Type Leaf $jarname
			$exists=$validpath
		}
		else {
			Set-Location $serverdir
			$accessible=$?
			if ($accessible -eq $true) {
				$validpath=Test-Path -Type Leaf $jarname
			}
			Set-Location $olddir
			$exists=Test-Path -Type Leaf $jarname
		}
		if ($validpath -eq $true) {
			$firstrun=Test-Path -Type Leaf .\eula.txt
			$firstrun=!$firstrun
		}
		elseif ($validpath -eq $false -and $exists -eq $true) {
			Write-Output "[WARN] This script could locate your Minecraft server."
			Write-Output "[WARN] However, it found the server where you started the script from."
			Write-Output "[WARN] This should not be intentional. Printing current variables..."
			Write-Output "[WARN] Please ensure the following variables are all correct:"
			Write-Output "serverdir: $serverdir"
			Write-Output "olddir: $olddir"
			Write-Output "jarname: $jarname"
			Write-Output "arglist: $arglist"
			Write-Output "[WARN] Press ctrl+C now to exit and fix the issue, or press any key to continue."
			$Host.UI.RawUI.ReadKey()
			if ($download -eq $true) {
				if ($accessible -eq 0) {
					Write-Output "[WARN] The specified server directory is currently inaccessible to this user."
					Write-Output "[WARN] Please double-check you have specified the right path to locate the server."
					Write-Output "Specified path: "$serverdir
					Write-Output "Please be aware that a valid server already does exist."
					Write-Output "Existing server path: "$olddir
					Write-Output "If you wish to run the server already available, please answer no here."
					createpath
				}
				else {
					Write-Output "[WARN] This script is capable of navigating to the specified path."
					Write-Output "[WARN] However, said path does NOT currently hold a Minecraft server."
					Write-Output "[WARN] Please double-check that the download and serverdir variables are of your choosing."
					Write-Output "Specified path: "$serverdir
					newserver
				}
			}
			else {
				Write-Output "[WARN] This script has Download Mode disabled at this time."
				Write-Output "[WARN] Since it is disabled, I cannot proceed with starting a new server from scratch."
				Write-Output "[WARN] However, I did find an existing server on this machine!"
				Write-Output "User-specified path: $serverdir"
				Write-Output "Current working path: $olddir"
				Write-Output "Changing path to the old directory and continuing script execution..."
				Set-Location $olddir
			}
			$firstrun=Test-Path -Type Leaf .\eula.txt
			$firstrun=!$firstrun
		}
		else {
			if ($download -eq $true) {
				if ($serverdir -eq ".\") {
					Write-Output "Download Mode is currently enabled. Downloading latest server jar to path:"
					Get-Location | Select-Object -Expand Path | Write-Output
					Write-Output "Current server JAR name: "$jarname
					newserver
				}
				else {
					Write-Output "[WARN] This script cannot locate your Minecraft server!"
					Write-Output "[WARN] Printing current script variables so the issue may be found..."
					Write-Output "serverdir: $serverdir"
					Write-Output "olddir: $olddir"
					Write-Output "jarname: $jarname"
					Write-Output "arglist: $arglist"
					if ($accessible -eq $false) {
						createpath
					}
					else {
						whichpath
					}
				}
			}
			else {
				Write-Output "Download Mode is disabled globally in the script. Cannot download server JAR file."
				Write-Output "Also, no valid server exists based on the settings of this script."
				Write-Output "Printing variables so any possible issues may be found..."
				Write-Output "serverdir: $serverdir"
				Write-Output "olddir: $olddir"
				Write-Output "jarname: $jarname"
			}
		}
		if ($firstrun -eq $true) {
			Write-Output "Welcome to the Minecraft community, and your new Minecraft server!"
			Write-Output "You will be required to accept the EULA in order to run the server."
			Write-Output "The server will run in the next 10 seconds so the EULA file can be generated."
			Write-Output "Do not delete the eula.txt file, as the server checks for it on every start."
			Write-Output "You must also set the single variable named eula in it to true."
			Write-Output "Otherwise the server will refuse to run entirely, and tell you why."
			countdown 10
			Write-Output "First run commencing..."
			serverstart
			Write-Output "The first run is now over! Please accept the EULA by editing the eula.txt file."
			Write-Output "Then come back to this terminal and press any key to launch the server!"
			$Host.UI.RawUI.ReadKey()
			Write-Output "Welcome back! Starting server now..."
			$running=Test-Path -Type Leaf .\.running
			if ($running -eq $true) {
				Write-Output "The server is currently running, or has abruptly crashed."
				Write-Output "This may happen if you close the terminal window whilst the server is running."
				Write-Output "Please make a copy of your server folder, remove the .running file, and proceed."
				Write-Output "If you don't run into any problems, you can delete the copy you just made."
				Write-Output "Otherwise, locate the running instance using htop or some similar program."
				Write-Output "This script will NOT proceed in an effort to prevent damage to the server."
				Write-Output "If you are certain no other instance is running, please re-run this script."
				Write-Output "However, before doing so, ensure the .running file no longer exists."
				Write-Output "If it does exist, this script will think the server is running already."
				Write-Output "When that happens, this warning message will appear when this script is ran."
				Write-Output "Press any key to exit..."
				$Host.UI.RawUI.ReadKey()
				exit 2
			}
			else {
				serverstart
			}
		}
		else {
			Write-Output "Welcome back! It seems this isn't the first run of this server."
			Write-Output "Checking that the eula.txt file has already been edited to say true..."
			$eula=Select-String -Path .\eula.txt -Pattern true -Quiet
			if ($eula -eq $true) {
				Write-Output "Starting server in 3 seconds."
				countdown 3
				serverstart
			}
			else {
				Write-Output "The EULA file has not been edited to say true."
				Write-Output "This file MUST be edited to contain 'eula=true' on its own line."
				Write-Output "Please edit the file eula.txt located in the following directory:"
				Get-Location | Select-Object -Expand Path | Write-Output
				Write-Output "Please restart it manually after you make the needed change."
				Write-Output "Press any key to exit..."
				$Host.UI.RawUI.ReadKey()
				exit 1
			}
		}
	}
	function scriptinit {
		realstart
		afterserverexit
	}
	scriptinit
}
else {
	function startserver {
		if ($serverdir -eq ".\") {
			$exists=Test-Path -Type Leaf $jarname
			$validpath=$exists
		}
		else {
			$accessible=Set-Location $serverdir
			if ($accessible -eq $true) {
				$validpath=Test-Path -Type Leaf $jarname
			}
			Set-Location $olddir
			$exists=Test-Path -Type Leaf $jarname
		}
		if ($validpath -eq $true) {
			$firstrun=Test-Path -Type Leaf .\eula.txt
			$firstrun=!$firstrun
		}
		elseif ($validpath -eq $false -and $exists -eq $true) {
			Set-Location $olddir
			$firstrun=Test-Path -Type Leaf .\eula.txt
			$firstrun=!$firstrun
		}
		else {
			exit 1
		}
		if ($firstrun -eq $true) {
			Start-Process -FilePath java.exe -ArgumentList "$fullarglist" -Wait -NoNewWindow -RedirectStandardOutput .\output.log -RedirectStandardError .\error.log
			exit 0
		}
		else {
			$eula=Select-String -Path .\eula.txt -Pattern "true"
			if ($eula -eq $true) {
				$conflict=Test-Path -Type Leaf .\.running
				if ($conflict -eq $false) {
					New-Item -Path .\.running
					if ($? -eq $false) {
						exit 1
					}
					else {
						Start-Process -FilePath java.exe -ArgumentList "$fullarglist" -Wait -NoNewWindow -RedirectStandardOutput .\output.log -RedirectStandardError .\error.log
						$serverexit=$LASTEXITCODE
						Remove-Item .\.running
					}
				}
				else {
					exit 1
				}
			}
			else {
				exit 1
			}
		}
	}
	function preinit {
		if ($download -eq $true) {
			basedlchecks
			if ($oldbuild -ne $build) {
				Invoke-WebRequest "$baseurl/builds/$build/downloads/$remotename" -OutFile ".new_server.jar"
				if ($? -eq $true) {
					Write-Output $build > .\.version
					startserver
				}
				else {
					exit 1
				}
			}
			else {
				startserver
			}
		}
		else {
			startserver
		}
	}
	preinit
	exit $serverexit
}