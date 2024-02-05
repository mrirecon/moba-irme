#!/bin/bash

set -eux

helpstr=$(cat <<- EOF
Preparation of traj, data, inversion and echo times for IR Radial Multi-echo FLASH.
-E number of echos
-R repetition time 
-G nth golden angle
-f number of spokes per frame (k-space)
-s number of slices
-h help
EOF
)

usage="Usage: $0 [-h] [-E nEcho] [-T TR] [-G GA] [-f nspokes_per_frame] [-s slices] <input> <out_data> <out_traj> <out_TI> <out_TE>"

slice=1
while getopts "hE:T:G:f:s:" opt; do
	case $opt in
	h) 
		echo "$usage"
		echo "$helpstr"
		exit 0 
		;;
        E) 
		nEcho=${OPTARG}
		;;
	T) 
		TR=${OPTARG}
		;;
	G) 
		GA=${OPTARG}
		;;
	f) 	
		nspokes_per_frame=${OPTARG}
		;;
	s) 	
		slices=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))

NECO=$nEcho
TR=$TR
GIND=$GA
slice=$slices

input=$(readlink -f "$1")
out_data=$(readlink -f "$2")
out_traj=$(readlink -f "$3")
out_TI=$(readlink -f "$4")
out_TE=$(readlink -f "$5")

#-----------------------------
# Prepare data and traj
#-----------------------------

# bart transpose 2 13 $input temp_kdat1
bart transpose 1  2 $input temp_kdat2
bart transpose 0  1 temp_kdat2 KDAT0

# --- dimensions ---
NSMP=$(bart show -d  1 KDAT0)
NSPK=$(bart show -d  2 KDAT0)
NMEA=$(bart show -d 10 KDAT0)
NSLI=1 # single-slice

# --- Reshape ---
bart transpose 2 9 KDAT0 tmp_KDAT0
bart reshape $(bart bitmask 9 10) 1 $((NSPK*NMEA)) tmp_KDAT0 tmp_KDAT2
bart transpose 2 10 tmp_KDAT2 KDAT2

TOT_NSPK=$(bart show -d 2 KDAT2)
TOT_NSPK0=$(bart show -d 2 KDAT0)

NCOI=8

# --- coil compression ---
bart cc -A -p $NCOI KDAT2 temp_kdat1

# --- from spoke dim to eco dim ---
NSPK1=$(( TOT_NSPK / NECO ))
bart reshape $(bart bitmask 2 5) $NECO $NSPK1 temp_kdat1 temp_kdat2
bart transpose 2 5 temp_kdat2 kdat1

# ------- traj ------
FSMP=$NSMP
# NMEA=1
NSPK0=$((TOT_NSPK0/NECO))
bart traj -x $NSMP -d $FSMP -y $NSPK0 -m $NSLI -l -t $NMEA -r -s $GIND -D -E -e $NECO -c TRAJ

# ------- gradient delay correction ------

CTR_SLI_NR=$(( ($NSLI == 1) ? (0) : ( NSLI/2 ) ))

bart slice 13 $CTR_SLI_NR kdat1 temp_kdat
bart slice 13 $CTR_SLI_NR TRAJ temp_traj

bart reshape $(bart bitmask 2 10) 1 $(( NSPK0 * NMEA )) temp_kdat temp_kdat_estdelay
bart reshape $(bart bitmask 2 10) 1 $(( NSPK0 * NMEA )) temp_traj temp_traj_estdelay

# number of spokes for GDC
TOT_SPK=$(( NSPK0 * NMEA ))

if [ ${TOT_SPK} -gt 80 ]; then
	NSPK4GDC=80
else
	NSPK4GDC=$((TOT_SPK))
fi

bart extract 10 $((TOT_SPK-NSPK4GDC)) $TOT_SPK temp_kdat_estdelay temp_kdat_estdelay_t
bart extract 10 $((TOT_SPK-NSPK4GDC)) $TOT_SPK temp_traj_estdelay temp_traj_estdelay_t

echo "> GDC using the central slice $CTR_SLI_NR and $NSPK4GDC spokes"

bart transpose 2 10 temp_kdat_estdelay_t temp_kdat_estdelay_a
bart transpose 2 10 temp_traj_estdelay_t temp_traj_estdelay_a

bart zeros 16 3 1 1 1 1 $NECO 1 1 1 1 1 1 1 1 1 1 GDC

IECO=0

while [ $IECO -lt $NECO ]; do

bart slice 5 $IECO temp_kdat_estdelay_a temp_kdat_estdelay_${IECO}
bart slice 5 $IECO temp_traj_estdelay_a temp_traj_estdelay_${IECO}

CTR=$(( FSMP/2 ))
DIF=$(( FSMP - NSMP ))
RADIUS=$(( CTR - DIF ))

# the echo position for even echoes are flipped

ECOPOS=$(( ($IECO%2 == 0) ? (RADIUS) : (RADIUS - 1) ))
LEN=$(( ECOPOS * 2 ))

if [ $(($IECO%2)) -eq 1 ]; then # even echoes
        bart flip $(bart bitmask 1) temp_kdat_estdelay_${IECO} temp_kk
        bart flip $(bart bitmask 1) temp_traj_estdelay_${IECO} temp_tt
else
        bart scale 1 temp_kdat_estdelay_${IECO} temp_kk
        bart scale 1 temp_traj_estdelay_${IECO} temp_tt
fi

bart resize 1 $LEN temp_kk temp_kk_r
bart resize 1 $LEN temp_tt temp_tt_r

bart estdelay -R temp_tt_r temp_kk_r temp_GDC_$IECO

let IECO=IECO+1
done

bart join 5 `seq -s" " -f "temp_GDC_%g" 0 $(( $NECO-1 ))` GDC

bart traj -x $NSMP -d $FSMP -y $NSPK0 -m $NSLI -l -t $NMEA -r -s $GIND -D -E -e $NECO -c -O -V GDC TRAJ_corr

bart reshape $(bart bitmask 2 10) $((NSPK0*NMEA)) 1 TRAJ_corr TRAJ_corr-1


# --- group all spokes to time dim ---
nspokes_per_frame=$nspokes_per_frame

bart reshape $(bart bitmask 2 10) $nspokes_per_frame $((NSPK0*NMEA/nspokes_per_frame)) TRAJ_corr-1 temp_tt
bart reshape $(bart bitmask 2 10) $nspokes_per_frame $((NSPK0*NMEA/nspokes_per_frame)) kdat1 temp_kk


bart transpose 5 9 temp_tt temp_tt-1
bart transpose 5 10 temp_tt-1 tmp2
bart scale 0.5 tmp2 $out_traj

bart transpose 5 9 temp_kk temp_kk-1
bart transpose 5 10 temp_kk-1 $out_data

rm temp*.{hdr,cfl}

#-----------------------------
# Prepare TI [s]
#-----------------------------

nTI=$(bart show -d5 $out_data)
spokes=$(bart show -d2 $out_data)

bart index 5 $nTI tmp1
# use local index from newer bart with older bart
#./index 5 $num tmp1
slices=1
bart scale $(($spokes * $TR * $slices)) tmp1 tmp2
bart ones 6 1 1 1 1 1 $nTI tmp1 
bart saxpy $((($spokes / 2) * $TR * $slices)) tmp1 tmp2 tmp3
bart scale 0.000001 tmp3 $out_TI

#-----------------------------
# Prepare TE [ms]
#-----------------------------

TE=(2260 4200 6140 8080 10100 12100 14100 16100 18100 20100 22100)
length=${#TE[@]}

bart ones 6 1 1 1 1 1 1 tmp1
n=0
for i in ${TE[@]}; do
        bart scale $i tmp1 tmp2-${n}
        n=$((n+1))
done

bart join 5 $(seq -f "tmp2-%g" 0 $(($length-1))) tmp-TE

bart scale 1e-3 tmp-TE tmp-TE1
bart transpose 5 9 tmp-TE1 tmp-TE2
bart extract 9 0 $NECO tmp-TE2 $out_TE

rm tmp*.{hdr,cfl} kdat*.{hdr,cfl} KDAT*.{hdr,cfl} TRAJ*.{hdr,cfl}
