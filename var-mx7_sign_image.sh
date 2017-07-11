#! /bin/bash

usage()
{
	echo "Usage: `basename "$0"` IMGFILE [IMGEFILE]..."
	echo "Note: for a U-Boot image, make sure its log file is present in the same directory"
	echo
}

if [ "$#" -eq 0 ]; then
	usage
	exit 1
fi

LOADADDR=0x80800000 ./var-sign_image.sh $@
