#!/bin/bash



set -e

usage="Usage: $0 [-D TD] [-r res] [-f] <reco> <reco_maps> <watert1map> <r2starmap> <fB0map> <fatt1map>"

# whether fat is in the reconstructed maps
fat=0

if [ $# -lt 5 ] ; then

        echo "$usage" >&2
        exit 1
fi
while getopts "hfD:r:" opt; do
	case $opt in
	h) 
		echo "$usage"
		exit 0 
		;;		
	D) 
		TD=${OPTARG} # time between center of inversion and the first RF pulse
		;;
	r) 
		res=${OPTARG}
		;;
	f) 
		fat=1
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND - 1))


reco=$(readlink -f "$1")
reco_maps=$(readlink -f "$2")
watert1map=$(readlink -f "$3")
r2starmap=$(readlink -f "$4")
fB0map=$(readlink -f "$5")

if (($fat == 1));
then
	fatt1map=$(readlink -f "$6")
fi

TD=$TD
res=$res

if [ ! -e ${reco}.cfl ] ; then
        echo "Input file 'reco' does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

bart resize -c 0 $res 1 $res $reco $reco_maps 

# Water T1
bart extract 6 0 3 $reco_maps tmp-w-maps
bart extract 6 0 1 tmp-w-maps tmp-w-ms
bart extract 6 1 2 tmp-w-maps tmp-w-m0
bart extract 6 2 3 tmp-w-maps tmp-w-r1s
bart scale 1. tmp-w-m0 tmp-w-m02
bart join 6 tmp-w-ms tmp-w-m02 tmp-w-r1s tmp-w-maps2 
bart looklocker -t0.0 -D$TD tmp-w-maps2 $watert1map

if (($fat == 1));
then
	# Fat T1
        bart extract 6 3 6 $reco_maps tmp-f-maps
        bart extract 6 0 1 tmp-f-maps tmp-f-ms
        bart extract 6 1 2 tmp-f-maps tmp-f-m0
        bart extract 6 2 3 tmp-f-maps tmp-f-r1s
        bart scale 1. tmp-f-m0 tmp-f-m02
        bart join 6 tmp-f-ms tmp-f-m02 tmp-f-r1s tmp-f-maps2 
	bart looklocker -t0.2 -D$TD tmp-f-maps2 $fatt1map
	bart extract 6 6 7 $reco_maps $r2starmap
	bart extract 6 7 8 $reco_maps tmp-B0
else
        bart extract 6 3 4 $reco_maps $r2starmap
	bart extract 6 4 5 $reco_maps tmp-B0
fi

# B0 map
bart creal tmp-B0 $fB0map

rm tmp*.{hdr,cfl}
