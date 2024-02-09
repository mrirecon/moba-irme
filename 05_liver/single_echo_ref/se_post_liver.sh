#!/bin/bash

set -euBx
set -o pipefail

usage="Usage: $0 [-R TR] [-r res] <reco> <t1map>"

if [ $# -lt 2 ] ; then

        echo "$usage" >&2
        exit 1
fi
while getopts "hR:r:" opt; do
	case $opt in
	h) 
		echo "$usage"
		exit 0 
		;;		
	R) 
		TR=${OPTARG}
		;;
	r) 
		res=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))


reco=$(readlink -f "$1")
t1map=$(readlink -f "$2")
TR=$TR
res=$res

if [ ! -e ${reco}.cfl ] ; then
        echo "Input file 'reco' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi


t=$(echo "scale=4; $TR/1000" | bc)

bart looklocker -t0.0 -D15.3e-3 $reco map 
bart resize -c 0 $res 1 $res map $t1map



