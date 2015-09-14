#!/bin/bash
# universal-install
function systemPackageMgr(){
	package=$1
	apt=`command -v apt-get`
	yum=`command -v yum`

	if [ -n "$apt" ]; then
		installMethod=‘deb’
		echo “Deb based”
		wget=`rpm -qa | grep wget`
		if [ -n "$wget” ]; then
			rpm -i wget
		fi
	elif [ -n "$yum" ]; then
    		installMethod=‘rpm’
		echo “RPM based”
	else
    		echo "Err: no path to apt-get or yum" >&2;
    		exit 1;
fi


