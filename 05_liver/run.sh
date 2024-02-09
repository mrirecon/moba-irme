#!/bin/bash

set -euBx
set -o pipefail

[ -d results ] && rm -rf results
mkdir results

# Load data

./data/load_data.sh

# Run reconstructions

TR=10600 #10600:1.6x1.6
overgrid=1.0

ne=7 # number of echos
GA=2
lambda=0.007
SPOKES=6 # no. of spokes per k-space frame
nframe=60 # total number of k-space frames
fB0_a=88
fB0_b=16
TD=15.3e-3
newton=20
scaling_fat=0.5
scaling_r2s=0.1
scaling_B0=0.1

slices=1


datasets=($(ls data/*.cfl | sed -e 's/\.cfl//'))

for file in "${datasets[@]}";
do
	NAME=$(basename $file)

	# All datasets except the single echo one
	if [ "liver_ss_t1ref" != $NAME ]
	then
		READ=$(bart show -d0 $file)
		NBR=$((READ / 2))

		./prep_liver.sh -E$ne -T10600 -G$GA -f$SPOKES -s$slices $file data traj TI TE
	
		./reco_liver.sh -R$lambda -F$nframe -a$fB0_a -b$fB0_b -i$newton -o${overgrid} -s$scaling_r2s -S$scaling_B0 -I TI TE traj \
		data results/reco_liver_${NAME} results/sens_liver_${NAME} | tee -a liver_${NAME}.log

		./post_liver.sh -f -D $TD -r $NBR results/{reco_liver,reco_liver_maps,watert1map_liver,r2starmap_liver,fB0map_liver,fatt1map_liver}_${NAME}


		# steady-state

		# Extract steady-state from data and trajectory
		NSPK=$(bart show -d2 traj)
		NFRM=$(bart show -d5 traj)

		bart extract 5 $((NFRM-20)) $NFRM traj tmp_t0
		bart extract 5 $((NFRM-20)) $NFRM data tmp_k0

		bart reshape $(bart bitmask 2 5) $((NSPK*20)) 1 tmp_t0 t0_ss2
		bart reshape $(bart bitmask 2 5) $((NSPK*20)) 1 tmp_k0 k0_ss2

		bart moba -i20 -d4 -g -D -m7 -R3 --img_dims $((READ/2)):$((READ/2)):1 -k --kfilter-2 -e1e-2 -o$overgrid -C200 -j0.0006 \
		--normalize_scaling --scale_data 500 --scale_psf 500 -b $fB0_a:$fB0_b -T0.9 -I M0_init \
		--positive-maps 0 \
		--other pinit=1:$scaling_fat:$scaling_r2s:$scaling_B0:1:1:1:1,pscale=1:$scaling_fat:$scaling_r2s:$scaling_B0:1:1:1:1,echo=TE \
		-t t0_ss2 k0_ss2 TI-tmp reco-wf-7e2 sens-wf-7e2

		bart resize -c 0 $NBR 1 $NBR reco-wf-7e2 results/reco_wf_ss_${NAME}
	fi
done

# single-echo reference

./single_echo_ref/run_se_liver.sh


rm *.{cfl,hdr}