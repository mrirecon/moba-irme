#!/bin/bash

set -euBx
set -o pipefail

# Estimate relative paths

FULL_PATH=$(realpath ${0})
REL_PATH=$(dirname ${FULL_PATH})

DATA=${REL_PATH}/../data/brain_ss_vol97_t1ref


READ=$(bart show -d0 $DATA)
res=$((READ/2))
TR=7560

GA=7
lambda=0.002
nstate=180
overgrid=1

bart reshape $(bart bitmask 1 10) 1 1140 $DATA ksp2
bart extract 10 0 600 ksp2 ksp3

nspokes=$(bart show -d10 ksp3)
nspokes_per_frame=10


bash ${REL_PATH}/se_prep_brain.sh -s$READ -R$TR -G$GA -p$nspokes -f$nspokes_per_frame -m1 -S1 -c$nstate ksp3 data2 traj2 TI2

bash ${REL_PATH}/se_reco_brain.sh -m1 -R$lambda -o$overgrid TI2 traj2 data2 ${REL_PATH}/../results/ss-brain-reco2 | tee -a reco2.log

bash ${REL_PATH}/se_post_brain.sh -R$TR -r$res ${REL_PATH}/../results/ss-brain-reco2 ${REL_PATH}/../results/ss-brain-t1map2


