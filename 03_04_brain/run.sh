#!/bin/bash

set -euBx
set -o pipefail


[ -d results ] && rm -rf results
mkdir results

# Load data

./data/load_data.sh

# Run reconstructions

datasets=($(ls data/*.cfl | sed -e 's/\.cfl//'))

for file in "${datasets[@]}";
do

	NAME=$(basename $file)

	# All datasets except the B0 and T1 ref
	if [ "brain_vol97_b0ref" == $NAME ] || [ "brain_ss_vol97_t1ref" == $NAME ];
	then
		echo "Reference scan is treated differently."
	else
		READ=$(bart show -d0 $file)
		ne=7 # number of echos
		TR=15600
		GA=2
		lambda=0.004
		SPOKES=6 # no. of spokes per k-space frame
		nframe=50 # total number of k-space frames
		fB0_a=22
		fB0_b=4
		newton=20
		overgrid=1.0
		NBR=$((READ / 2))
		TD=15.3e-3
		scaling_R2s=0.06
		scaling_fB0=0.05

		SLICES=1

		./prep_brain.sh -E$ne -T$TR -G$GA -s$SLICES -f$SPOKES $file data traj TI TE

		./reco_brain.sh -R$lambda -F$nframe -a$fB0_a -b$fB0_b -i$newton -o$overgrid -s$scaling_R2s -S$scaling_fB0 -I TI TE traj data results/reco_${NAME} results/sens_${NAME} | tee -a brain.log

		./post_brain.sh -f -D $TD -r $NBR results/reco_${NAME} results/reco_maps_${NAME} results/watert1map2_${NAME} results/r2starmap2_${NAME} results/fB0map2_${NAME} results/fatt1map2_${NAME}
	fi
done


# Run Single-echo reference T1 map

./single_echo_ref/run_se_brain.sh

# Run B0 Reference analysis

./b0map/load_ref_b0map.sh results/b0map

rm *.{cfl,hdr}

