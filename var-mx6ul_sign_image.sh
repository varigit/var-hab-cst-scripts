#! /bin/bash

usage()
{
	echo "Usage: `basename "$0"` IMGFILE [IMGEFILE]..."
	echo "Note: for U-Boot/SPL images, make sure their log file is present in the same directory"
	echo
}

if [ "$#" -eq 0 ]; then
	usage
	exit 1
fi

LOADADDR=0x82000000 ./var-sign_image.sh $@
