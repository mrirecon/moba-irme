#!/bin/bash

set -euBx
set -o pipefail

# Estimate relative paths

FULL_PATH=$(realpath ${0})
REL_PATH=$(dirname ${FULL_PATH})

DATA=${REL_PATH}/../data/liver_ss_t1ref

READ=$(bart show -d0 $DATA)
res=$(($READ/2))
TR=2540

GA=2
lambda=0.008
nstate=180
overgrid=1.0


bart reshape $(bart bitmask 1 10) 1 2050 $DATA ksp2
bart extract 10 0 1575 ksp2 ksp3

nspokes=$(bart show -d10 ksp3)
nspokes_per_frame=25


bash ${REL_PATH}/se_prep_liver.sh -s$READ -R$TR -G$GA -p$nspokes -f$nspokes_per_frame -m1 -S1 -c$nstate ksp3 data2 traj3 TI2

bash ${REL_PATH}/se_reco_liver.sh -m1 -k -R$lambda -o$overgrid TI2 traj3 data2 ${REL_PATH}/../results/ss-liver-reco2 | tee -a reco2.log

bash ${REL_PATH}/se_post_liver.sh -R$TR -r$res ${REL_PATH}/../results/ss-liver-reco2 ${REL_PATH}/../results/ss-liver-t1map2

