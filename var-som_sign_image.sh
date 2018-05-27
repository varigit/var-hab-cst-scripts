#! /bin/bash

usage()
{
	echo "Usage: SOC=<soc> `basename "$0"` IMGFILE [IMGEFILE]..."
	echo "soc is one of {mx6, mx6ul, mx6ull, mx7}"
	echo "Note: for U-Boot/SPL images, make sure their log file is present in the same directory"
	echo
}


if [ "$#" -eq 0 ]; then
	usage
	exit 1
fi


if [ "$SOC" == "mx6" ]; then
	export LOADADDR=0x12000000
elif [ "$SOC" == "mx6ul" ]; then
	export LOADADDR=0x82000000
elif [ "$SOC" == "mx6ull" ]; then
	export LOADADDR=0x82000000
	export ENGINE=SW
elif [ "$SOC" == "mx7" ]; then
	export LOADADDR=0x80800000
else
	usage
	exit 1
fi


./var-sign_image.sh $@
