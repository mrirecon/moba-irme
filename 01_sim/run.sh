#!/bin/bash


set -euBx
set -o pipefail

[ -d results ] && rm -rf results
mkdir results

READ=384
ne=7 # number of echos
TR=12700 # micro second
TR0=$(echo "scale=4; $TR*0.000001" | bc)

GA=2
lambda=0.0015
SPOKES=3 # no. of spokes per k-space frame
nkframe=100 # total number of k-space frames
fB0_a=11
fB0_b=4
NBR=$((READ / 2))
TD=0
newton=20
overgrid=1.0
s_r2s=0.04
s_fb0=0.05

# Part A and B
# Bland-Altman Analysis of Individual ROI Analysis

./prep_simu.sh -S$READ -E$ne -T$TR -G$GA -f$SPOKES -M$nkframe data traj TI TE

./reco_simu.sh -I -R$lambda -F$nkframe -a$fB0_a -b$fB0_b -i$newton -o$overgrid -s$s_r2s -S$s_fb0 TI TE traj data results/reco results/sens | tee -a reco.log

./post_simu.sh -f -D $TD -r $NBR -s $s_r2s -S $s_fb0 results/reco results/reco_maps results/watert1map results/r2starmap results/fB0map results/fatt1map


# Part C and D
# Run Fat Fraction Simulation

./fat_fraction_curve/run_fat_frac_simu.sh

rm *.{cfl,hdr,log} || true
