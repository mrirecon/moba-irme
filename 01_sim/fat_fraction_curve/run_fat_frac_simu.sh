#!/bin/bash

set -euBx
set -o pipefail

FULL_PATH=$(realpath ${0})
REL_PATH=$(dirname ${FULL_PATH})

READ=384
ne=7 # number of echos
TR=5000 # micro second
TR0=$(echo "scale=4; $TR*0.000001" | bc)

GA=2
lambda=0.001
SPOKES=9 # o. of spokes per k-space frame
nkframe=100 # total number of k-space frames
fB0_a=11
fB0_b=4
NBR=$((READ / 2))
TD=0.
newton=20
overgrid=1.0
s_r2s=0.04
s_fb0=0.05
sms=1

# Fat Fraction Values
FF_VALUES=(0 0.05 0.1 0.15 0.2 0.25 0.3)

# Phases
PH=("in" "out")
iop=(1 2)

for FF in "${FF_VALUES[@]}";
do
	for i in `seq 0 $((${#PH[@]}-1))`;
	do
		bash ${REL_PATH}/prep_fat_frac.sh -S$READ -E$ne -T$TR -G$GA -f$SPOKES -M$nkframe -F$FF -P"${iop[$i]}" data_FF${FF}_"${PH[$i]}" \
		traj_FF${FF}_"${PH[$i]}" TI_FF${FF}_"${PH[$i]}" TE_FF${FF}_"${PH[$i]}"

		bash ${REL_PATH}/reco_fat_frac.sh -k -m$sms -R$lambda -o$overgrid TI_FF${FF}_"${PH[$i]}" traj_FF${FF}_"${PH[$i]}" data_FF${FF}_"${PH[$i]}" \
		${REL_PATH}/../results/reco_FF${FF}_"${PH[$i]}" ${REL_PATH}/../results/sens_FF${FF}_"${PH[$i]}"

		# Post-Process
		bart resize -c 0 192 1 192 ${REL_PATH}/../results/reco_FF${FF}_"${PH[$i]}" ${REL_PATH}/../results/reco_192_FF${FF}_"${PH[$i]}"
		bart looklocker -t0 -D0 ${REL_PATH}/../results/reco_192_FF${FF}_"${PH[$i]}" ${REL_PATH}/../results/t1map_192_FF${FF}_"${PH[$i]}"

		rm *.{cfl,hdr}
	done
done