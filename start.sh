#!/bin/sh
# shellcheck disable=SC2027,SC2086

touch ./.test
readonly=$?
if [ $readonly = 0 ]; then rm ./.test; else exit 1; fi

download=1
jarname="./server.jar"
arglist="-Xms16G -Xmx16G -jar $jarname"
gctuningbig="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
# gctuningsmall="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
fullarglist="$gctuningbig $arglist"

if [ $download = 1 ]; then
	release="1.21.1"
	baseurl="https://api.papermc.io/v2/projects/paper/versions/"$release
	build="$(curl -sX GET "$baseurl"/ -H 'accept: application/json' | jq '.builds [-1]')"
	dlbuild=$baseurl"/builds/"$build"/downloads/paper-"$release"-"$build".jar"
	checksum="$(curl -sX GET "$baseurl/builds/$build" -H 'accept: application/json' | jq -r '.downloads.application.sha256')"
	if [ -f ./.build ]; then oldbuild=$(grep . ./.build); else oldbuild=0; fi
	if [ -f ./.release ]; then oldrelease=$(grep . ./.release); else oldrelease=0; fi
	if [ $oldbuild != $build ] || [ $oldrelease != $release ]; then
		wget $dlbuild -O ./.new_server.jar > /dev/null 2>&1
		exitcode=$?
		if [ $exitcode = 0 ]; then
			realsum=$(sha256sum ./.new_server.jar | awk '{ print $1 }')
			if [ $realsum = $checksum ]; then
				if [ -f $jarname ]; then rm $jarname; fi
					mv ./.new_server.jar $jarname
					echo $build > ./.build
					echo $release > ./.release
			else rm ./.new_server.jar; fi
		fi
	fi
fi

if [ -f $jarname ]; then
	java $fullarglist
	serverexit=$?
	exit $serverexit
else exit 2; fi