#! /bin/bash

usage()
{
	echo "Usage: `basename "$0"` IMGFILE [IMGEFILE]..."
	echo "Notes:"
	echo "- For U-Boot/SPL images, make sure their log file is present in the same directory"
	echo "- For kernel images, make sure the variable LOADADDR is set to their ram location"
	echo
}

attach_ivt()
{
	IMAGE_SIZE=`wc -c < $1`
	ALIGNED_SIZE=$(( ($IMAGE_SIZE + 0x1000 - 1) & ~ (0x1000 - 1) ))

	printf "Extend $1 from 0x%x to 0x%x...\n" $IMAGE_SIZE $ALIGNED_SIZE
	objcopy -I binary -O binary --pad-to $ALIGNED_SIZE --gap-fill=0x00 $1 ${1}-pad

	echo "Generate IVT"
	./var-genIVT $LOADADDR `printf "0x%x" $ALIGNED_SIZE`

	echo "Attach IVT to output image: ${1}-ivt"
	cat ${1}-pad ivt.bin > ${1}-ivt
	rm ${1}-pad
}

attach_csf_data()
{
	echo "Generate csf data..."
	cp var-default.csf ${1}.csf
	printf "Blocks = $RAM_AUTH_AREA_START   $IMG_SIGN_AREA_START   $IMG_SIGN_AREA_SIZE   \"${1}\"\n" >> ${1}.csf

	if [ "$IS_SPL" == "true" ]; then
		printf "\n[Unlock]\nEngine = CAAM\nFeatures = RNG\n" >> ${1}.csf
	fi

	./cst -i ${1}.csf -o ${1}_csf.bin

	echo "Merge image and csf data to output image: ${1}_signed"
	cat ${1} ${1}_csf.bin > ${1}_signed
}


if [ "$#" -eq 0 ]; then
	usage
	exit 1
fi

while [[ $# -gt 0 ]]; do
	IMAGE=$1
	IS_SPL=false

	echo
	echo "Input image: $IMAGE"
	if [ ! -f $IMAGE ]; then
		echo "Error: No such file $IMAGE"
		shift
		continue
	fi

	if [ -f ${IMAGE}.log ]; then
		HAB_BLOCKS=`grep 'HAB Blocks:' ${IMAGE}.log`
		RAM_AUTH_AREA_START=`awk '{print $3}' <<< ${HAB_BLOCKS}`
		IMG_SIGN_AREA_START=`awk '{print $4}' <<< ${HAB_BLOCKS}`
		IMG_SIGN_AREA_SIZE=`awk '{print $5}' <<< ${HAB_BLOCKS}`

		if [ -z "$RAM_AUTH_AREA_START" -o -z "$IMG_SIGN_AREA_START" -o -z "$IMG_SIGN_AREA_SIZE" ]; then
			echo "Error: log file is corrupted"
			shift
			continue
		fi

		for arg in RAM_AUTH_AREA_START  IMG_SIGN_AREA_START  IMG_SIGN_AREA_SIZE; do
			eval value=\$$arg
			if [ ${value:0:2} != 0x ]; then
				value=0x${value}
				eval $arg=\$value
			fi
		done

		if [ `grep 'Image Type:' ${IMAGE}.log | grep -c 'Freescale IMX Boot Image'` -eq 1 ]; then
			IS_SPL=true
		fi

		attach_csf_data ${IMAGE}
	else
		if [ -z "$LOADADDR" ]; then
			echo "Error: No log file or LOADADDR"
			shift
			continue
		fi

		attach_ivt ${IMAGE}

		RAM_AUTH_AREA_START=${LOADADDR}
		IMG_SIGN_AREA_START=0x0000
		IMG_SIGN_AREA_SIZE=$(printf "0x%x" `wc -c < ${IMAGE}-ivt`)

		attach_csf_data ${IMAGE}-ivt
	fi

	echo
	shift
done
