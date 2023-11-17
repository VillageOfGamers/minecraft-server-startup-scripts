# This is to eliminate the progress bars from the several used Invoke-WebRequest invocations in this script.
# Please keep this variable in this script and set to this exact value.
$ProgressPreference='SilentlyContinue'

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
# The general consensus is to keep these 2 the same, it just makes life easier as it allows the JVM to not have to deallocate and reallocate memory constantly.

# I recommend leaving 1GB of RAM or more available if you are using Linux without a graphical environment.
# If you are using a desktop environment in Linux, leave 2GB of RAM or more available for the OS.
# This script has been tested in Windows using PowerShell 7. It has NOT been tested with older PowerShell versions or under UNIX OSes with PowerShell 7.
# Please edit arglist to allocate the appropriate amount of RAM for YOUR specific system!
# The general consensus is that you shouldn't need more than 8GB of RAM unless some of your plugins are going nuts (Dynmap takes a lot for example).
# You may expand the RAM capacity further if you're REALLY wanting to stretch how much data FAWE (or normal WorldEdit) can hold in the buffer at one time.
# Also see the comments for fullarglist below; these tips are necessary!
$jarname="server.jar"
$arglist="-Xms12G -Xmx12G -jar $jarname"

# This variable is explicitly here JUST to provide a way to not use the already-installed JRE environment if you do not want to use it.
# This is especially useful if you cannot fully install the JRE you wish to use, but you can run it from a different location.
# Otherwise you may leave it set to "java.exe" to use your currently installed version of Java, rather than having to specify a full path.
# WARNING: YOU MUST BE USING JAVA 16 OR LATER! IT WILL BREAK OTHERWISE! THIS IS NOT HYPERBOLE; I HAVE TRIED TO USE OLDER JAVA VERSIONS AND IT DOES NOT WORK!
$javapath="java.exe"

# THESE VARIABLES ARE NOT TO BE TOUCHED UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING!
# These arguments for the Java instance have been hand-tuned by the Minecraft community to provide optimal performance of the server.
# The user-adjustable argument list is ABOVE these comment lines; those control how much RAM it can use, and the name of the JAR to launch.
$gctuningbig="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
# $gctuningsmall="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"

# If you are using this to start a Minecraft server with LESS THAN 12GB OF RAM, please use gctuningsmall instead of gctuningbig.
# gctuningsmall is set up so that the server doesn't get starved of RAM on lower RAM allocation, and is beneficial for a low-RAM system.
$fullarglist="$gctuningbig $arglist -nogui"

# This olddir variable is to store the initial working directory this script got launched from.
# This is because the script DOES change which directory the shell uses if the serverdir variable above is NOT set to ./ per its default.
# Note: This does NOT mean the directory the FILE sits in, it means the path your SHELL'S current working directory was at the time this script got started.
$olddir=Get-Location

# These variables are here specifically to dictate the URL to pull the latest server JAR from.
# I just so happen to have this file set to default to the PaperMC API at this point in time; not everyone in the world uses PaperMC, I get that.
# The only time you should ever need to change this URL format is if they ever change how the API works, or where you're getting your server JAR from.
# As of 8/23/2023, the server I have been writing and improving this script for is on version 1.20.1.
function basedlchecks {
	$mcver="1.20.1"
	$baseurl="https://api.papermc.io/v2/projects/paper/versions/$mcver"
	Invoke-WebRequest "$baseurl/builds/" -UseBasicParsing -OutFile .\.parseme.json
	$getbuilds=Get-Content .\.parseme.json | ConvertFrom-Json
	Remove-Item .\.parseme.json
	$build=$getbuilds.builds[-1]
	$buildnum=$build.build
	Invoke-WebRequest "$baseurl/builds/$buildnum" -UseBasicParsing -OutFile .\.parseme.json
	$buildinfo=Get-Content .\.parseme.json | ConvertFrom-Json
	Remove-Item .\.parseme.json
	$remotename=$buildinfo.downloads.application.name
	$checksum=$buildinfo.downloads.application.sha256
	try {
		$versionstring=$(Select-String . .\.version)
	}
	catch {
		$oldbuild=0
	}
	if ($null -ne $versionstring) {
		$oldbuild=$versionstring.Line
	}
	$dlarray=@() # init empty array to pass all needed vars out in one shot
	$dlarray+=$baseurl # baseurl is now index 0 of dlarray.
	$dlarray+=$buildnum # buildnum is now index 1 of dlarray.
	$dlarray+=$remotename # remotename is now index 2 of dlarray.
	$dlarray+=$oldbuild # oldbuild is now index 3 of dlarray.
	$dlarray+=$checksum # checksum is now index 4 of dlarray.
	return $dlarray # actually pass the vars out
}

if ($interactive -eq $true) {
	# This function is just a wait loop, with the i variable getting set by whichever part of the script calls it.
	# The i variable is the number of seconds to wait via this loop, while printing a countdown each second.
	# the out variable is what determines what TYPE of output gets sent to the terminal. If it is not set, it defaults to stdout.
	function countdown ($i, $out) {
		while ($i -gt 0) {
			Switch ($out) {
				out {Write-Host "$i..."}
				err {Write-Error "$i..."}
				war {Write-Warning "$i..."}
				ver {Write-Verbose "$i..."}
				dbg {Write-Debug "$i..."}
				inf {Write-Information "$i..."}
				Default {Write-Host "$i..."}
			}
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
			$dlarray=basedlchecks
			$baseurl=$dlarray[0]
			$buildnum=$dlarray[1]
			$remotename=$dlarray[2]
			$oldbuild=$dlarray[3]
			$checksum=$dlarray[4]
			if ($oldbuild -ne $buildnum) {
				function keepdl ($baseurl ,$buildnum ,$remotename ,$checksum) {
					Write-Host "Download mode enabled. This script will replace the old JAR with the new one."
					Write-Host "Do you wish to continue with the attempt to download the latest version? (Y/N)"
					$key=$Host.UI.RawUI.ReadKey()
					$keepdl=$key.Character
					Switch ($keepdl) {
						Y {
							Write-Host "Download mode confirmed by user. Continuing with download of latest JAR."
							Invoke-WebRequest "$baseurl/builds/$buildnum/downloads/$remotename" -OutFile ".new_server.jar"
							$result=Get-FileHash -Algorithm SHA256 .\.new_server.jar
							$realsum=$result.Hash
							if ($realsum -eq $checksum) {
								Write-Host "Download of latest server version successful. Proceeding with launch."
								Write-Host $buildnum > .\.version
								Remove-Item -Path "$jarname" -ErrorAction SilentlyContinue
								Move-Item -Path ".new_server.jar" -Destination "$jarname"
							} else {
								Write-Warning "Download of latest version failed. However this script can continue."
								Write-Warning "The download was attempted and did fail. Checked via SHA256 sum match."
								Write-Warning "However the filename used was '.new_server.jar', not $jarfile."
								Write-Warning "Because of this sanity check, the known good JAR is still available to use."
								function useoldjar {
									Write-Host "Would you like to use the last known good JAR and continue to start the server? (Y/N)"
									$key=$Host.UI.RawUI.ReadKey()
									$continue=$key.Character
									Switch ($continue) {
										Y {
											Write-Host "You have chosen to continue using the last known good JAR."
											Write-Host "This script will now delete the failed download and continue execution."
											Remove-Item -Path .\.new_server.jar
										}
										N {
											Write-Warning "You have chosen to exit upon failure to download the new build."
											Write-Warning "This script will now exit. If the download failure persists,"
											Write-Warning "please double-check the download variables, or disable download mode."
											Write-Warning "You may do so by setting the download variable near the top of this script to 0."
											exit 1
										}
										Default {
											Write-Error "Invalid choice. Your choices are yes (Y) or no (N)."
											useoldjar
										}
									}
								}
								useoldjar
							}
						}
						N {
							Write-Host "Download mode disabled by user choice. Halting download of new version."
						}
						Default {
							Write-Error "Invalid choice. Your choices are yes (Y) or no (N)."
							keepdl $baseurl $buildnum $remotename $checksum
						}
					}
				}
				keepdl $baseurl $buildnum $remotename $checksum
			} else {
				Write-Host "Download mode enabled. $jarname also has no new releases at this time."
				Write-Host "Disabling download mode for this run only due to the lack of difference."
			}
		} else {
			Write-Host "Download mode disabled. $jarname will remain at its current version."
			Write-Host "All logic surrounding the support of downloading a new version is off."
			Write-Host "This means no related variables are set, and no related files will be modified."
		}
		$running=Test-Path -Type Leaf .\.running
		if ($running -eq $true) {
			Write-Error "The server has run into a crash at some point, or is running."
			Write-Error "Please fix the issue, and get rid of the .running file to proceed."
			Write-Error "This script will now exit due to the running condition..."
			exit 2
		}
		New-Item .\.running -ErrorVariable $denied | Out-Null
		if ($null -ne $denied) {
			Write-Error "Touch has run into an error. Could not create running file!"
			Write-Error "Please ensure this user accont has WRITE access to path:"
			Get-Location | Select-Object -Expand Path | Write-Error
			Write-Error "Please press any key to exit. I cannot continue without WRITE access."
			$Host.UI.RawUI.ReadKey() | Out-Null
			exit 2
		} else {
			$process=Start-Process -FilePath $javapath -ArgumentList "$fullarglist" -Wait -NoNewWindow -PassThru
			$serverexit=$process.ExitCode
			Remove-Item .\.running
			return $serverexit
		}
	}
	function askrestart {
		Write-Host "Would you like to restart the Minecraft server? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$restart=$key.Character
		Switch ($restart) {
			Y {
				Write-Host "The server will restart at your request."
				realstart
			}
			N {
				Write-Host "Thank you for using Giantvince1's Minecraft server startup automater!"
				Write-Host "We hope to see you soon! Exiting script now."
				exit 0
			}
			Default {
				Write-Error "Invalid choice. Your choices are yes (Y) or no (N)."
				askrestart
			}
		}
	}
	function newserver {
		Write-Host "Would you like to truly start a new server here in this path? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$newserver=$key.Character
		Switch ($newserver) {
			Y {
				Write-Host "Okay, a NEW Minecraft server instance will be started within the folder:"
				Get-Location | Select-Object -Expand Path | Write-Host
				Write-Host "If this is NOT desired, you will have 10 seconds to press CTRL+C."
				Write-Host "This will give you time to stop the attempt before the download begins."
				countdown 10 out
				Write-Host "No CTRL+C received, continuing new instance setup..."
			}
			N {
				Write-Host "Per your request, this script will NOT be attempting to start a new server."
				Write-Host "This script will now exit as there is no valid server to start up with."
				exit 1
			}
			Default {
				Write-Error "Invalid choice. Your options are yes (Y) or no (N)."
				newserver
			}
		}
	}
	function whichpath {
		Write-Host "I am able to traverse into the path you have specified previously."
		Write-Host "However neither that path nor where this script was ran from have a valid server."
		Write-Host "Which path did you intend for me to use for a Minecraft server? (O/N) [O=old,N=new]"
		$key=$Host.UI.RawUI.ReadKey()
		$whichpath=$key.Character
		Switch ($whichpath) {
			O {
				Write-Host "You have chosen the old directory. Changing to directory and printing path..."
				Write-Host "Current path: $olddir"
				Set-Location $olddir
				newserver
			}
			N {
				Write-Host "You have chosen the new directory. Changing to directory and printing path..."
				Write-Host "Current path: $serverdir"
				Set-Location $serverdir
				newserver
			}
			Default {
				Write-Error "Invalid choice. Your choices are old (O) or new (N)."
				whichpath
			}
		}
	}
	function createpath {
		Write-Host "Do you want this script to create this path for you, if able? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$createpath=$key.Character
		Switch ($createpath) {
			Y {
				Write-Host "Attempting to start up and initialize NEW server instance..."
				New-Item -Type Directory -Force $serverdir | Out-Null
				$accessible=$?
				if ($accessible -eq $true) {
					Set-Location $serverdir
					Write-Host "The specified path was successfully created, and your user has write access!"
					Write-Host "Current directory: $serverdir"
					Write-Host "Old directory: $olddir"
					Write-Host "Continuing with startup script execution..."
					newserver
				} else {
					Write-Error "Unable to create path to the specified directory!"
					Write-Error "Specified path: $serverdir"
					Write-Error "The only path I can access directly is the location I was started at!"
					Write-Error "Since I am unable to start a server which I cannot access,"
					Write-Error "and you, the user, have specified to try the specified path anyway,"
					Write-Error "I am NOT going to go to my starting path and start the one that lives there."
					Write-Error "This script is now going to exit."
					exit 1
				}
			}
			N {
				Write-Host "You have told me NOT to make a new directory."
				Write-Host "Directory in use: $olddir"
				Write-Host "Please double-check the serverdir variable in this script!"
				Write-Host "Continuing execution inside the old directory..."
				Set-Location $olddir
			}
			Default {
				Write-Error "Invalid choice. Your options are yes (Y) or no (N)."
				createpath
			}
		}
	}
	function askmodify ($loop) {
		Write-Host "The server has been shut down. Do you wish to change any variables? (Y/N)"
		$key=$Host.UI.RawUI.ReadKey()
		$changes=$key.Character
		Switch ($changes) {
			Y {
				if ($loop -gt 1) {
					Write-Host "Since you plan on changing things, this script will not loop again."
				} else {
					Write-Host "Since you plan on changing things, this script will not loop."
				}
				Write-Host "Once you finish editing the variables, please restart the script manually."
				Write-Host "This script is now going to exit to allow you to modify its variables."
				Write-Host "Please press any key to continue..."
				$Host.UI.RawUI.ReadKey() | Out-Null
				exit 0
			}
			N {
				if ($loop -gt 1) {
					Write-Host "Since you don't plan on changing anything, this script is able to loop again."
				} else {
					Write-Host "Since you don't plan on changing anything, this script is able to loop."
				}
				Write-Host "This is by design; this script is capable of re-using itself infinitely."
				Write-Host "It wil also only do so each time the user WANTS it to. It will not forkbomb."
				askrestart
			}
			Default {
				Write-Error "Invalid choice. Your choices are yes (Y) or no (N)."
				askmodify
			}
		}
	}
	function afterserverexit ($loop ,$serverexit) {
		while ($serverexit -eq 0) {
			askmodify $loop
		}
		if ($serverexit -ne 0) {
			Write-Error "The server has encountered some sort of error. Please check the console logs."
			Write-Error "This script will NOT be offering you the ability to restart the server."
			Write-Error "I recommend you look through the server logs and look for errors."
			Write-Error "This script will not exit so that you may still read the server console log."
			Write-Error "Please press any key to exit..."
			$Host.UI.RawUI.ReadKey() | Out-Null
			exit 2
		}
	}
	function realstart {
		$loop=$loop+1
		if ($serverdir -eq ".\") {
			$validpath=Test-Path -Type Leaf $jarname
			$exists=$validpath
		} else {
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
		} elseif ($validpath -eq $false -and $exists -eq $true) {
			Write-Warning "This script could locate your Minecraft server."
			Write-Warning "However, it found the server where you started the script from."
			Write-Warning "This should not be intentional. Printing current variables..."
			Write-Warning "Please ensure the following variables are all correct:"
			Write-Warning "serverdir: $serverdir"
			Write-Warning "olddir: $olddir"
			Write-Warning "jarname: $jarname"
			Write-Warning "arglist: $arglist"
			Write-Warning "Press ctrl+C now to exit and fix the issue, or press any key to continue."
			$Host.UI.RawUI.ReadKey() | Out-Null
			if ($download -eq $true) {
				if ($accessible -eq 0) {
					Write-Warning "The specified server directory is currently inaccessible to this user."
					Write-Warning "Please double-check you have specified the right path to locate the server."
					Write-Warning "Specified path: "$serverdir
					Write-Warning "Please be aware that a valid server already does exist."
					Write-Warning "Existing server path: "$olddir
					Write-Warning "If you wish to run the server already available, please answer no here."
					createpath
				} else {
					Write-Warning "This script is capable of navigating to the specified path."
					Write-Warning "However, said path does NOT currently hold a Minecraft server."
					Write-Warning "Please double-check that the download and serverdir variables are of your choosing."
					Write-Warning "Specified path: "$serverdir
					newserver
				}
			} else {
				Write-Host "[WARN] This script has Download Mode disabled at this time."
				Write-Host "[WARN] Since it is disabled, I cannot proceed with starting a new server from scratch."
				Write-Host "[WARN] However, I did find an existing server on this machine!"
				Write-Host "User-specified path: $serverdir"
				Write-Host "Current working path: $olddir"
				Write-Host "Changing path to the old directory and continuing script execution..."
				Set-Location $olddir
			}
			$firstrun=Test-Path -Type Leaf .\eula.txt
			$firstrun=-not $firstrun
		} else {
			if ($download -eq $true) {
				if ($serverdir -eq ".\") {
					Write-Host "Download Mode is currently enabled. Downloading latest server jar to path:"
					Get-Location | Select-Object -Expand Path | Write-Host
					Write-Host "Current server JAR name: "$jarname
					$firstrun=$true
					newserver
				} else {
					Write-Host "[WARN] This script cannot locate your Minecraft server!"
					Write-Host "[WARN] Printing current script variables so the issue may be found..."
					Write-Host "serverdir: $serverdir"
					Write-Host "olddir: $olddir"
					Write-Host "jarname: $jarname"
					Write-Host "arglist: $arglist"
					if ($accessible -eq $false) {
						createpath
					} else {
						whichpath
					}
				}
			} else {
				Write-Host "Download Mode is disabled globally in the script. Cannot download server JAR file."
				Write-Host "Also, no valid server exists based on the settings of this script."
				Write-Host "Printing variables so any possible issues may be found..."
				Write-Host "serverdir: $serverdir"
				Write-Host "olddir: $olddir"
				Write-Host "jarname: $jarname"
			}
		}
		if ($firstrun -eq $true) {
			Write-Host "Welcome to the Minecraft community, and your new Minecraft server!"
			Write-Host "You will be required to accept the EULA in order to run the server."
			Write-Host "The server will run in the next 10 seconds so the EULA file can be generated."
			Write-Host "Do not delete the eula.txt file, as the server checks for it on every start."
			Write-Host "You must also set the single variable named eula in it to true."
			Write-Host "Otherwise the server will refuse to run entirely, and tell you why."
			countdown 10 out
			Write-Host "First run commencing..."
			$serverexit=serverstart
			Write-Host "The first run is now over! Please accept the EULA by editing the eula.txt file."
			Write-Host "Then come back to this terminal and press any key to launch the server!"
			$Host.UI.RawUI.ReadKey() | Out-Null
			Write-Host "Welcome back! Starting server now..."
			$running=Test-Path -Type Leaf .\.running
			if ($running -eq $true) {
				Write-Host "The server is currently running, or has abruptly crashed."
				Write-Host "This may happen if you close the terminal window whilst the server is running."
				Write-Host "Please make a copy of your server folder, remove the .running file, and proceed."
				Write-Host "If you don't run into any problems, you can delete the copy you just made."
				Write-Host "Otherwise, locate the running instance using htop or some similar program."
				Write-Host "This script will NOT proceed in an effort to prevent damage to the server."
				Write-Host "If you are certain no other instance is running, please re-run this script."
				Write-Host "However, before doing so, ensure the .running file no longer exists."
				Write-Host "If it does exist, this script will think the server is running already."
				Write-Host "When that happens, this warning message will appear when this script is ran."
				Write-Host "Press any key to exit..."
				$Host.UI.RawUI.ReadKey() | Out-Null
				exit 2
			} else {
				$serverexit=serverstart
			}
		} else {
			Write-Host "Welcome back! It seems this isn't the first run of this server."
			Write-Host "Checking that the eula.txt file has already been edited to say true..."
			$eula=Select-String -Path .\eula.txt -Pattern true -Quiet
			if ($eula -eq $true) {
				Write-Host "Starting server in 3 seconds."
				countdown 3 out
				$serverexit=serverstart
			} else {
				Write-Host "The EULA file has not been edited to say true."
				Write-Host "This file MUST be edited to contain 'eula=true' on its own line."
				Write-Host "Please edit the file eula.txt located in the following directory:"
				Get-Location | Select-Object -Expand Path | Write-Host
				Write-Host "Please restart it manually after you make the needed change."
				Write-Host "Press any key to exit..."
				$Host.UI.RawUI.ReadKey() | Out-Null
				exit 1
			}
		}
		$passthru=@()
		$passthru+=$loop
		$passthru+=$serverexit
		return $passthru
	}
	function scriptinit {
		$passthru=realstart
		$loop=$passthru[0]
		$serverexit=$passthru[1]
		afterserverexit $loop $serverexit
	}
	scriptinit
} else {
	function startserver {
		if ($serverdir -eq ".\") {
			$exists=Test-Path -Type Leaf $jarname
			$validpath=$exists
		} else {
			$accessible=Set-Location $serverdir
			if ($accessible -eq $true) {
				$validpath=Test-Path -Type Leaf $jarname
			}
			Set-Location $olddir
			$exists=Test-Path -Type Leaf $jarname
		}
		if ($validpath -eq $true) {
			$firstrun=Test-Path -Type Leaf .\eula.txt
			$firstrun=-not $firstrun
		}
		elseif ($validpath -eq $false -and $exists -eq $true) {
			Set-Location $olddir
			$firstrun=Test-Path -Type Leaf .\eula.txt
			$firstrun=-not $firstrun
		} else {
			exit 1
		}
		if ($firstrun -eq $true) {
			Start-Process -FilePath $javapath -ArgumentList "$fullarglist" -Wait -NoNewWindow -RedirectStandardOutput .\output.log -RedirectStandardError .\error.log
			exit 0
		} else {
			$eula=Select-String -Path .\eula.txt -Pattern "true"
			if ($eula -eq $true) {
				$conflict=Test-Path -Type Leaf .\.running
				if ($conflict -eq $false) {
					New-Item -Path .\.running
					if ($? -eq $false) {
						exit 1
					} else {
						Start-Process -FilePath $javapath -ArgumentList "$fullarglist" -Wait -NoNewWindow -RedirectStandardOutput .\output.log -RedirectStandardError .\error.log
						$serverexit=$LASTEXITCODE
						Remove-Item .\.running
					}
				} else {
					exit 1
				}
			} else {
				exit 1
			}
		}
		return $serverexit
	}
	function preinit {
		if ($download -eq $true) {
			$dlarray=basedlchecks
			$baseurl=$dlarray[0]
			$buildnum=$dlarray[1]
			$remotename=$dlarray[2]
			$oldbuild=$dlarray[3]
			if ($oldbuild -ne $buildnum) {
				Invoke-WebRequest "$baseurl/builds/$buildnum/downloads/$remotename" -OutFile ".new_server.jar"
				if ($? -eq $true) {
					Write-Host $build > .\.version
					startserver
				} else {
					exit 1
				}
			} else {
				startserver
			}
		} else {
			startserver
		}
	}
	preinit
	exit $serverexit
}