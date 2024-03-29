#!/bin/bash

set -euBx
set -o pipefail

usage="Usage: $0 [-R lambda] [-F nframe] [-a fB0_a] [-b fB0_b] [-i newton] [-o overgrid] [-I] [-M] [-f] <TI> <TE> <traj> <ksp> <output> <output_sens>"

if [ $# -lt 5 ] ; then

        echo "$usage" >&2
        exit 1
fi

# whether to initialize fB0 with a 3-echo moba
init=0

# whether to include fat in the model
fat=1

SMS=''

overgrid=1.25

while getopts "hR:F:a:b:i:o:IMf" opt; do
	case $opt in
	h) 
		echo "$usage"
		exit 0 
		;;		
	R) 
		lambda=${OPTARG}
		;;
        F) 
		nframe=${OPTARG}
		;;
        a) 
		fB0_a=${OPTARG}
		;;
        b) 
		fB0_b=${OPTARG}
		;;
        i) 
		newton=${OPTARG}
		;;
        o) 
		overgrid=${OPTARG}
		;;
        I) 
		init=1
		;;
	M) 
		SMS='-M'
		;;
        f) 
		fat=0
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done
shift $(($OPTIND -1 ))

TI=$(readlink -f "$1")
TE=$(readlink -f "$2")
traj=$(readlink -f "$3")
ksp=$(readlink -f "$4")
reco=$(readlink -f "$5")
sens=$(readlink -f "$6")

lambda=$lambda
nframe=$nframe
fB0_a=$fB0_a
fB0_b=$fB0_b
overgrid=$overgrid

if [ ! -e ${TI}.cfl ] ; then
        echo "Input TI file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${TE}.cfl ] ; then
        echo "Input TE file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${traj}.cfl ] ; then
        echo "Input traj file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e ${ksp}.cfl ] ; then
        echo "Input ksp file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi


bart extract 5 0 $nframe $traj TRAJ_moba
bart extract 5 0 $nframe $ksp kdat_moba
bart extract 5 0 $nframe $TI TI_moba

# Initialization
dimx=$(bart show -d1 $ksp)

bart ones 6 $((dimx/2)) $((dimx/2)) 1 1 1 1 ones
bart resize -c 0 $dimx 1 $dimx ones mask
bart scale 2.0 mask fat_mask # R1s for fat is larger

bart zeros 6 $dimx $dimx 1 1 1 1 zeros_mask


scaling_fat=0.5
scaling_r2s=0.1
scaling_B0=0.1

# Initializa fB0 with 3-echo moba recon
if (($init == 1));
then
        # Extract stady-state data
        NSPK=$(bart show -d2 TRAJ_moba)
        NFRM=$(bart show -d5 TRAJ_moba)

        bart extract 5 $((NFRM-12)) $NFRM TRAJ_moba tmp_t0
        bart extract 5 $((NFRM-12)) $NFRM kdat_moba tmp_k0

        bart reshape $(bart bitmask 2 5) $((NSPK*12)) 1 tmp_t0 t0_ss
        bart reshape $(bart bitmask 2 5) $((NSPK*12)) 1 tmp_k0 k0_ss

        bart extract 9 0 3 t0_ss tmp-TRAJ_moba-3e
        bart extract 9 0 3 k0_ss tmp-kdat_moba-3e
        bart extract 9 0 3 $TE tmp-TE_moba-3e

        bart ones 6 1 1 1 1 1 1 TI-tmp

        bart moba -i15 -d4 -g -D -m6 -R3 --img_dims $((dimx/2)):$((dimx/2)):1 --kfilter-2 -o$overgrid -C150 -j0.005 \
        --normalize_scaling --scale_data 500 --scale_psf 500 -B0.0 -b 22:8 --other pinit=1:$scaling_fat:$scaling_B0:1:1:1:1:1,pscale=1:$scaling_fat:$scaling_B0:1:1:1:1:1,echo=tmp-TE_moba-3e \
        -t tmp-TRAJ_moba-3e tmp-kdat_moba-3e TI-tmp reco2-wf-3e sens2-wf-3e

	# Prepare initialization file
	## Compensate for internal scaling by "1/$scaling"

        bart extract 6 0 1 reco2-wf-3e water

        bart extract 6 1 2 reco2-wf-3e fat
	bart scale $(echo "scale=6; 1/$scaling_fat" | bc) fat fat2

        bart extract 6 2 3 reco2-wf-3e fB0
	bart scale $(echo "scale=6; 1/($scaling_B0*1000)" | bc) fB0 fB02

        bart join 6 water water mask fat2 fat2 mask zeros_mask fB02 M_init
fi


if (($fat == 1));	# Ms_w, M0_w, R1*_w, Ms_f, M0_f, R1*_f, R2*, fB0
then
        recon_type=9

	bart moba -i$newton -d4 -g -D -m$recon_type -R3 --img_dims $((dimx/2)):$((dimx/2)):1 -o$overgrid -k --kfilter-2 -C300 -j$lambda \
	--normalize_scaling --scale_data 500 --scale_psf 500 --other pinit=1:1:1:1:1:1:$scaling_r2s:$scaling_B0,pscale=1:1:1:1:1:1:$scaling_r2s:$scaling_B0,echo=$TE -B0. -T0.5 -I M_init -b $fB0_a:$fB0_b \
	-t TRAJ_moba kdat_moba TI_moba $reco $sens

else	# Ms, M0, R1*, R2*, fB0
        recon_type=8
        bart join 6 mask mask mask zeros_mask fB02 M_init2

	bart moba -i$newton -d4 -g -D -m$recon_type -R3 --img_dims $((dimx/2)):$((dimx/2)):1 -o$overgrid -k --kfilter-2 -C300 -j$lambda \
	--normalize_scaling --scale_data 500 --scale_psf 500 --other pinit=1:1:1:$scaling_r2s:$scaling_B0:1:1:1,pscale=1:1:1:$scaling_r2s:$scaling_B0:1:1:1,echo=$TE -B0. -T0.5 -I M_init2 -b $fB0_a:$fB0_b \
	-t TRAJ_moba kdat_moba TI_moba $reco $sens
fi

rm tmp*.{hdr,cfl}
