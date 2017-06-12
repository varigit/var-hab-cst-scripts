#!/bin/sh

for ((i=0; i<8; i++))
do
	offset=$((i * 4))
	printf "fuse prog -y 3 $i %s\n" `hexdump -s $offset -n 4  -e '/4 "0x"' -e '/4 "%X""\n"' ../crts/SRK_1_2_3_4_fuse.bin`
done
