#!/bin/bash

set -euBx
set -o pipefail

helpstr=$(cat <<- EOF
Preparation of traj, data, inversion and echo times for IR Radial Multi-echo FLASH.
-S number of samples
-E number of echos
-R repetition time 
-G nth golden angle
-f number of spokes per frame (k-space)
-h help
EOF
)

usage="Usage: $0 [-h] [-S nSMP] [-E nEcho] [-T TR] [-G GA] [-f nspokes_per_frame] [-M NMEA_for_recon] <out_data> <out_traj> <out_TI> <out_TE>"


while getopts "hS:E:T:G:f:M:" opt; do
	case $opt in
	h) 
		echo "$usage"
		echo "$helpstr"
		exit 0 
		;;
	S) 
		nSMP=${OPTARG}
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
	M) 	
		NMEA_for_recon=${OPTARG}
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))

out_data=$(readlink -f "$1")
out_traj=$(readlink -f "$2")
out_TI=$(readlink -f "$3")
out_TE=$(readlink -f "$4")

[ ! -d results ] && mkdir results

# simulation
NECO=$((nEcho+1))
NSPK=9
NMEA=50
NI=$((NSPK*NMEA))
N=$((NECO*NMEA*NSPK))
TR=$TR
TE=1600
NSLI=1
GIND=$GA
NMEA_for_recon=$NMEA_for_recon

NSMP=$nSMP

bart traj -x $NSMP -y $NSPK -t$NMEA -r -D -E -G -s2 -e $((NECO-1)) -c tmp_traj1

bart reshape $(bart bitmask 2 10) $NI 1 tmp_traj1 tmp_traj2

bart scale 0.5 tmp_traj2 tmp_traj
bart phantom -k -s8 -T -b -t tmp_traj basis_geom

TR1=$(echo "scale=4; $TR*0.000001" | bc)
TE1=$(echo "scale=4; $TE*0.000001" | bc)

T1=(3 2.0 1.8 1.6 1.4 1.2 1.0 0.8 0.6 0.4 0.2)

T1_FAT=(0.3 0.35 0.4 0.3 0.35 0.4 0.3 0.35 0.4 0.3 0.34)

T2=(0.2  0.125  0.105  0.085  0.065 0.055 0.045 0.035 0.025 0.015 0.01)

FF=(0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2 0.2)

OFFRES_FAT=(`seq -50 10 50`)

# Store values in cfl

bart vec "${T1[@]}" ref_t1w
bart vec "${T1_FAT[@]}" ref_t1f
bart vec "${T2[@]}" ref_t2
bart vec "${FF[@]}" ref_ff
bart vec -- "${OFFRES_FAT[@]}" ref_offr

bart join 11 ref_t1w ref_t1f ref_t2 ref_ff ref_offr tmp
# bart extract 0 1 "${#T1[@]}" tmp tmp2
bart transpose 0 6 tmp results/ref_values


# Simulate signals
for i in `seq 0 $((${#T1[@]}-1))`; do

        echo -e "Tube $i\t T1: ${T1[$i]} s,\tT2[$i]: ${T2[$i]} s,\tT1_FAT[$i]: ${T1_FAT[$i]} s,\tOFFRES_FAT[$i]: ${OFFRES_FAT[$i]} s"

	bart signal 	-I -C -r$TR1 -e$TE1 -n$N -m$NECO -d${FF[$i]} \
			-1 ${T1[$i]}:${T1[$i]}:1 -2 ${T2[$i]}:${T2[$i]}:1 \
			-0 ${OFFRES_FAT[$i]}:${OFFRES_FAT[$i]}:1 -4 ${T1_FAT[$i]}:${T1_FAT[$i]}:1 \
			tmp_signal_$(printf "%02d" $i)

	# echo -e "${T1[$i]}\t${T1_FAT[$i]}\t${T2[$i]}\t${OFFRES_FAT[$i]}" >> $FILE
done

# Join individual simulations
bart join 7 $(ls tmp_signal_*.cfl | sed -e 's/\.cfl//') tmp_signal

bart reshape $(bart bitmask 6 7) ${#T1[@]} 1 tmp_signal signal_all

bart reshape $(bart bitmask 4 5) $NI $NECO signal_all tmp_1

bart extract 5 1 $NECO tmp_1 tmp_2

bart transpose 4 2 tmp_2 tmp_3

bart fmac -s 64 basis_geom tmp_3 tmp_data0

bart transpose 5 9 tmp_traj tmp_traj1

bart extract 2 0 $((nspokes_per_frame*$NMEA_for_recon)) tmp_traj1 tmp_traj1_1

bart reshape $(bart bitmask 2 5) $nspokes_per_frame $NMEA_for_recon tmp_traj1_1 $out_traj

bart transpose 5 9 tmp_data0 tmp_data0_1
bart transpose 2 5 tmp_data0_1 tmp_data0_2

bart extract 5 0 $((nspokes_per_frame*NMEA_for_recon)) tmp_data0_2 tmp_data0_3

bart reshape $(bart bitmask 2 5) $nspokes_per_frame $NMEA_for_recon tmp_data0_3 tmp_data_0

# add noise to the simulated dataset 
for (( i=0; i <= 7; i++ )) ; do

        bart slice 3 $i tmp_data_0 tmp
        bart noise -n200 tmp tmp_ksp_$i
done

bart join 3 $(ls tmp_ksp_*.cfl | sed -e 's/\.cfl//') tmp_data
rm tmp_ksp_*.{cfl,hdr}

nTE=$(bart show -d9 tmp_data)

bart index 9 $nTE tmp1
bart scale $TE tmp1 tmp2
bart ones 10 1 1 1 1 1 1 1 1 1 $nTE tmp1
bart saxpy $TE tmp1 tmp2 tmp3
bart scale 0.001 tmp3 $out_TE


nTI=$(bart show -d5 tmp_data)
spokes=$(bart show -d2 tmp_data)

bart index 5 $nTI tmp1
bart scale $(($spokes * $TR)) tmp1 tmp2
bart ones 6 1 1 1 1 1 $nTI tmp1 
echo $((($spokes / 2) * $TR))
bart saxpy $((($spokes / 2) * $TR)) tmp1 tmp2 tmp3
bart scale 0.000001 tmp3 $out_TI


# Coil Compression

bart cc -p2 -A tmp_data $out_data

rm tmp*.{hdr,cfl}