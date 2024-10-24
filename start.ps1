$ProgressPreference='SilentlyContinue'

New-Item .test -ItemType File
$writable=$?
if ($writable -eq true) {
	Remove-Item .test
} else {
	exit 1
}

$download=1
$jarname="server.jar"
$arglist="-Xms16G -Xmx16G -jar $jarname"
$javapath="java.exe"
$gctuningbig="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
# $gctuningsmall="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1"
$fullarglist="$gctuningbig $arglist -nogui"

if ($download -eq 1) {
	$release="1.21.1"
	$baseurl="https://api.papermc.io/v2/projects/paper/versions/$release"
	Invoke-WebRequest "$baseurl/builds/" -UseBasicParsing -OutFile .parseme.json
	$getbuilds=Get-Content .parseme.json | ConvertFrom-Json
	Remove-Item .parseme.json
	$build=$getbuilds.builds[-1]
	$buildnum=$build.build
	Invoke-WebRequest "$baseurl/builds/$buildnum" -UseBasicParsing -OutFile .parseme.json
	$buildinfo=Get-Content .parseme.json | ConvertFrom-Json
	Remove-Item .parseme.json
	$remotename=$buildinfo.downloads.application.name
	$checksum=$buildinfo.downloads.application.sha256
	try {
		$versionstring=$(Select-String . .build)
	}
	catch {
		$oldbuild=0
	}
	if ($null -ne $versionstring) {
		$oldbuild=$versionstring.Line
	}
	try {
		$releasestring=$(Select-String . .release)
	}
	catch {
		$oldrelease=0
	}
	if ($null -ne $releasestring) {
		$oldrelease=$releasestring.Line
	}
	if ($oldbuild -ne $buildnum) -or ($oldrelease -ne $release) {
		Invoke-WebRequest "$baseurl/builds/$buildnum/downloads/$remotename" -OutFile ".new_server.jar"
		$result=Get-FileHash -Algorithm SHA256 .new_server.jar
		$realsum=$result.Hash
		if ($realsum -eq $checksum) {
			Write-Host $buildnum > .build
			Write-Host $release > .release
			Remove-Item -Path "$jarname"
			Move-Item -Path ".new_server.jar" -Destination "$jarname"
		} else {
			exit 1
		}
	}
}

$exists=Test-Path $jarname -Type Leaf
if ($exists -eq $true) {
	$process=Start-Process -FilePath $javapath -ArgumentList "$fullarglist" -Wait -NoNewWindow -PassThru
	$serverexit=$process.ExitCode
	return $serverexit
} else {
	exit 2
}