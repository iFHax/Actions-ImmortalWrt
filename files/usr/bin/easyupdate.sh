#!/bin/bash


function checkEnv() {
	if !type sysupgrade >/dev/null 2>&1; then
		writeLog 'Your firmware does not contain sysupgrade and does not support automatic updates.'
		exit
	fi
}

function writeLog() {
	now_time='['$(date +"%Y-%m-%d %H:%M:%S")']'
	echo ${now_time} $1 | tee -a '/tmp/easyupdatemain.log'
}

function shellHelp() {
	checkEnv
	cat <<EOF
Your firmware already includes sysupgrade and supports automatic updates.
Parameters:
    -c                     Get the cloud firmware version
    -d                     Download the cloud firmware
    -f filename            Flash firmware from given file
    -u                     One-click firmware update
EOF
}

function getCloudVer() {
	checkEnv
	github=$(cat /etc/openwrt_release | sed -n "s/DISTRIB_GITHUB='\(\S*\)'/\1/p")
	github=(${github//// })
	curl "https://api.github.com/repos/${github[2]}/${github[3]}/releases/latest" | jsonfilter -e '@.tag_name' | sed -e 's/.*\([0-9]\{12\}.*\)/\1/'
}

function downCloudVer() {
	checkEnv
	writeLog 'Reading GitHub project address...'
	github=$(cat /etc/openwrt_release | sed -n "s/DISTRIB_GITHUB='\(\S*\)'/\1/p")
	writeLog "GitHub project address: $github"
	github=(${github//// })
	writeLog 'Checking for EFI firmware...'
	if [ -d "/sys/firmware/efi/" ]; then
		suffix="combined-efi.img.gz"
	else
		suffix="combined.img.gz"
	fi
	writeLog "Using firmware type: $suffix"
	writeLog 'Getting cloud firmware download link...'
	url=$(curl "https://api.github.com/repos/${github[2]}/${github[3]}/releases/latest" | jsonfilter -e '@.assets[*].browser_download_url' | sed -n "/$suffix/p")
	writeLog "Cloud firmware URL: $url"
	mirror=''
	writeLog "Using mirror URL: $mirror"
	fileName=(${url//// })
	curl -o "/tmp/${fileName[7]}-sha256" -L "$mirror${url/${fileName[7]}/sha256sums}"
	curl -m 10000 -o "/tmp/${fileName[7]}" -L "$mirror$url" >/tmp/easyupdate.log 2>&1 &
	writeLog 'Started downloading firmware, logs in /tmp/easyupdate.log'
}

function flashFirmware() {
	checkEnv
	if [[ -z "$file" ]]; then
		writeLog 'Please specify the file name.'
	else
		writeLog 'Checking if configuration should be preserved...'
		writeLog "Preserve configuration: $res"
		writeLog 'Flashing firmware, logs in /tmp/easyupdate.log'
		sysupgrade /tmp/$file >/tmp/easyupdate.log 2>&1 &
	fi
}

function checkSha() {
	if [[ -z "$file" ]]; then
		for filename in $(ls /tmp); do
			if [[ "${filename#*.}" = "img.gz" && "${filename}" == *"-combined"* ]]; then
				file=$filename
			fi
		done
	fi
	cd /tmp && sha256sum -c <(grep $file $file-sha256)
}

function updateCloud() {
	checkEnv
	writeLog 'Reading local firmware version...'
	lFirVer=$(cat /etc/openwrt_release | sed -n "s/DISTRIB_VERSIONS='.*\([0-9]\{12\}\).*'/\1/p")
	writeLog "Local firmware version: $lFirVer"
	writeLog 'Reading cloud firmware version...'
	cFirVer=$(getCloudVer)
	writeLog "Cloud firmware version: $cFirVer"
	lFirVer=$(date -d "${lFirVer:0:4}-${lFirVer:4:2}-${lFirVer:6:2} ${lFirVer:8:2}:${lFirVer:10:2}" +%s)
	cFirVer=$(date -d "${cFirVer:0:4}-${cFirVer:4:2}-${cFirVer:6:2} ${cFirVer:8:2}:${cFirVer:10:2}" +%s)
	if [ $cFirVer -gt $lFirVer ]; then
		writeLog 'Update required.'
		checkShaRet=$(checkSha)
		if [[ $checkShaRet =~ 'OK' ]]; then
			writeLog 'Checksum verified.'
			file=${checkShaRet:0:-4}
			flashFirmware
		else
			downCloudVer
			i=0
			while [ $i -le 100 ]; do
				log=$(cat /tmp/easyupdate.log)
				str='transfer closed'
				if [[ $log =~ $str ]]; then
					writeLog 'Download error: transfer closed.'
					i=101
					break
				else
					str='Could not resolve host'
					if [[ $log =~ $str ]]; then
						writeLog 'Download error: could not resolve host.'
						i=101
						break
					else
						str='100\s.+M\s+100.+--:--:--'
						if [[ $log =~ $str ]]; then
							writeLog 'Download completed.'
							i=100
							break
						else
							echo $log | sed -n '$p'
							if [[ $i -eq 99 ]]; then
								writeLog 'Download timed out.'
								break
							fi
						fi
					fi
				fi
				let i++
				sleep 3
			done
			if [[ $i -eq 100 ]]; then
				writeLog 'Preparing to flash firmware...'
				checkShaRet=$(checkSha)
				if [[ $checkShaRet =~ 'OK' ]]; then
					writeLog 'Checksum verified.'
					file=${checkShaRet:0:-4}
					flashFirmware
				else
					writeLog 'Checksum verification failed.'
				fi
			fi
		fi
	else
		writeLog "Firmware is up to date."
	fi
}

if [[ -z "$1" ]]; then
	shellHelp
else
	case $1 in
	-c)
		getCloudVer
		;;
	-d)
		downCloudVer
		;;
	-f)
		file=$2
		flashFirmware
		;;
	-k)
		file=$2
		checkSha
		;;
	-u)
		updateCloud
		;;
	*)
		shellHelp
		;;
	esac
fi
