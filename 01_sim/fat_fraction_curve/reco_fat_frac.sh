#!/bin/bash

set -euBx
set -o pipefail

usage="Usage: $0 [-m sms] [-R lambda] [-k] [-o overgrid] <TI> <traj> <ksp> <output> <output_sens>"

if [ $# -lt 4 ] ; then

        echo "$usage" >&2
        exit 1
fi

k_filter=0

while getopts "hm:R:ko:" opt; do
	case $opt in
	h) 
		echo "$usage"
		exit 0 
		;;		
	m) 
		sms=${OPTARG}
		;;
	R) 
		lambda=${OPTARG}
		;;
	k)
		k_filter=1
		;;
	o)
		overgrid=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))

TI=$(readlink -f "$1")
traj=$(readlink -f "$2")
ksp=$(readlink -f "$3")
reco=$(readlink -f "$4")

if [ "$#" -lt 5 ] ; then
        sens=""
else
	sens=$(readlink -f "$5")
fi

if [ ! -e ${TI}.cfl ] ; then
        echo "Input file 'TI' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${traj}.cfl ] ; then
        echo "Input file 'traj' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${ksp}.cfl ] ; then
        echo "Input file 'ksp' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

# model-based T1 reconstruction:

readout=$(bart show -d1 $traj)
img_size=$((readout/2))

if [ $k_filter -eq 1 ] ; then
	opts="-L -g -k --kfilter-2 -i20 -d4 -B0. -C400 -R3 -o$overgrid"
else
	opts="-L -g -i40 -d4 -B0.0 -C400 -R3 -o$overgrid"
fi

echo $k_filter

opts+=" --img_dims $img_size:$img_size:1 --normalize_scaling --scale_data 500 --scale_psf 500"

if [ $sms -eq 1 ]; then
        bart moba $opts -j$lambda -N -t $traj $ksp $TI $reco $sens
else
        bart moba $opts -M -j$lambda -t $traj $ksp $TI $reco $sens
fi


