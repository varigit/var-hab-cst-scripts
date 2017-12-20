#!/bin/sh

if [ $# -ne 1 ] || [ "$1" != "mx6" -a "$1" != "mx6ul" -a "$1" != "mx7" ]; then
	echo "Usage: `basename "$0"` SOC"
	echo
	echo "SOC is one of {mx6, mx6ul, mx7}"
	echo
	exit 1
fi


if [ "$1" == "mx7" ]; then
	bank=6
else
	bank=3
fi
word=0

for ((i=0; i<8; i++))
do
	if [ "$1" == "mx7" -a $i -eq 4 ]; then
		bank=7
		word=0
	fi
	offset=$((i * 4))
	printf "fuse prog -y $bank $word %s\n" `hexdump -s $offset -n 4  -e '/4 "0x"' -e '/4 "%X""\n"' ../../crts/SRK_1_2_3_4_fuse.bin`
	((word++))
done
