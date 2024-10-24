# Minecraft Server Startup Scripts

This is a collection of shell-based scripts designed to start up a Minecraft server.
It also performs sanity checks to ensure everything operates smoothly.

I have done everything I can to ensure the PowerShell version is cross-platform as well as the POSIX SH version.
However, unless specific programs are installed, neither will work.
First and foremost, they need Java installed and in your $PATH, no matter the OS of choice.
Second, on Linux, you need `jq`, `wget`, `curl`, `grep`, `awk`, and `sha256sum` as executables.
On Windows, you will be fine, as long as you have the JSON cmdlets installed before you run this script.
All of these should be available via your system's package manager of choice.
However, none of these are needed unless download mode is enabled. It just requires Java if set to be manually updated.
