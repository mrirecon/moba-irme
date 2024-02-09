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
-F fat fraction
-h help
EOF
)

usage="Usage: $0 [-h] [-S nSMP] [-E nEcho] [-T TR] [-G GA] [-f nspokes_per_frame] [-M NMEA_for_recon] [-F Fat_fraction] [-P in_out_phase] <out_data> <out_traj> <out_TI> <out_TE>"

in_out_phase=0
while getopts "hS:E:T:G:f:M:F:P:" opt; do
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
	F) 	
		Fat_fraction=${OPTARG}
		;;
	P) 	
		in_out_phase=${OPTARG}
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


# simulation
NECO=$((nEcho+1))
NSPK=9
NMEA=100
NI=$((NSPK*NMEA))
N=$((NECO*NMEA*NSPK))
TR=$TR
TE=1600
in_out_phase=$in_out_phase

if [[ $in_out_phase -eq 1 ]]
then
  TE=2300
elif [[ $in_out_phase -eq 2 ]]
then
  TE=1150
fi

NSLI=1
GIND=$GA
NMEA_for_recon=$NMEA_for_recon
Fat_fraction=$Fat_fraction

NSMP=$nSMP

bart traj -x $NSMP -y $NSPK -t$NMEA -r -D -E -G -s2 -e $((NECO-1)) -c tmp_traj1


bart reshape $(bart bitmask 2 10) $NI 1 tmp_traj1 tmp_traj2


bart scale 0.5 tmp_traj2 tmp_traj
bart phantom -k -s8 -T -b -t tmp_traj basis_geom2

TR1=$(echo "scale=4; $TR*0.000001" | bc)
TE1=$(echo "scale=4; $TE*0.000001" | bc)


T1=(3 2.0 1.8 1.6 1.4 1.2 1.0 0.8 0.6 0.4 0.2)

T1_FAT=(0.3 0.35 0.4 0.3 0.35 0.4 0.3 0.35 0.4 0.3 0.34)

T2=(0.2  0.125  0.105  0.085  0.065 0.055 0.045 0.035 0.025 0.015 0.01)

# R2=(5  8  9.5  11.8  15.4 18.2 22.2 28.6 40 66.7 100)

OFFRES_FAT=(`seq -50 10 50`)

# Simulate signals
for i in `seq 0 $((${#T1[@]}-1))`;
do

        echo -e "Tube $i\t T1: ${T1[$i]} s,\tT2[$i]: ${T2[$i]} s,\tT1_FAT[$i]: ${T1_FAT[$i]} s,\tOFFRES_FAT[$i]: ${OFFRES_FAT[$i]} s"

	bart signal 	-I -C -r$TR1 -e$TE1 -n$N -m$NECO -d$Fat_fraction \
			-1 ${T1[$i]}:${T1[$i]}:1 -2 ${T2[$i]}:${T2[$i]}:1 \
			-0 ${OFFRES_FAT[$i]}:${OFFRES_FAT[$i]}:1 -4 ${T1_FAT[$i]}:${T1_FAT[$i]}:1 \
			tmp_signal_$(printf "%02d" $i)

	# echo -e "${T1[$i]}\t${T1_FAT[$i]}\t${T2[$i]}\t${OFFRES_FAT[$i]}" >> $FILE
done

# Join individual simulations
bart join 7 $(ls tmp_signal_*.cfl | sed -e 's/\.cfl//') tmp_signal

bart reshape $(bart bitmask 6 7) ${#T1[@]} 1 tmp_signal signal_all

bart reshape $(bart bitmask 4 5) $NI $NECO signal_all tmp

bart extract 5 1 $NECO tmp tmp_2

bart transpose 4 2 tmp_2 tmp_3

bart fmac -s 64 basis_geom2 tmp_3 tmp_data0

bart transpose 5 9 tmp_traj tmp_traj1

bart extract 2 0 $((nspokes_per_frame*$NMEA_for_recon)) tmp_traj1 tmp_traj1_1

bart reshape $(bart bitmask 2 5) $nspokes_per_frame $NMEA_for_recon tmp_traj1_1 full_traj

bart transpose 5 9 tmp_data0 tmp_data0_1
bart transpose 2 5 tmp_data0_1 tmp_data0_2

bart extract 5 0 $((nspokes_per_frame*NMEA_for_recon)) tmp_data0_2 tmp_data0_3

bart reshape $(bart bitmask 2 5) $nspokes_per_frame $NMEA_for_recon tmp_data0_3 tmp_data_0

# add noise to the simulated dataset 
for (( i=0; i <= 7; i++ ));
do
        bart slice 3 $i tmp_data_0 tmp
        bart noise -n200 tmp tmp_ksp_$i
done

bart join 3 $(ls tmp_ksp_*.cfl | sed -e 's/\.cfl//') full_data
rm tmp_ksp_*.{cfl,hdr}

nTE=$(bart show -d9 full_data)

bart index 9 $nTE tmp1
bart scale $TE tmp1 tmp2
bart ones 10 1 1 1 1 1 1 1 1 1 $nTE tmp1
bart saxpy $TE tmp1 tmp2 tmp3
bart scale 0.001 tmp3 $out_TE


nTI=$(bart show -d5 full_data)
spokes=$(bart show -d2 full_data)

bart index 5 $nTI tmp1
bart scale $(($spokes * $TR)) tmp1 tmp2
bart ones 6 1 1 1 1 1 $nTI tmp1 
echo $((($spokes / 2) * $TR))
bart saxpy $((($spokes / 2) * $TR)) tmp1 tmp2 tmp3
bart scale 0.000001 tmp3 full_TI


bart cc -p2 -A full_data cc_data

# Only first 2/3 of timesteps # FIXME: Better explanation
bart extract 5 0 80 9 0 1 full_traj $out_traj
bart extract 5 0 80 9 0 1 cc_data $out_data
bart extract 5 0 80 full_TI $out_TI

rm tmp*.{cfl,hdr}