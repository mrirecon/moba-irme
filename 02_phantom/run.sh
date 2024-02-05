#!/bin/bash


[ -d results ] && rm -rf results
mkdir results

# Load data

./data/load_data.sh

# Run reconstructions

READ=$(bart show -d0 data/nist)
ne=7 # number of echos
TR=15600
GA=2
lambda=0.0005
SPOKES=6 # no. of spokes per k-space frame
nframe=50 # total number of k-space frames
fB0_a=22
fB0_b=4
newton=20
overgrid=1.0
NBR=$((READ / 2))
TD=15.3e-3
scaling_R2s=0.1
scaling_fB0=0.1

SLICES=1


./prep_nist.sh -E$ne -T$TR -G$GA -s$SLICES -f$SPOKES data/nist data traj TI TE

./reco_nist.sh -R$lambda -F$nframe -f -a$fB0_a -b$fB0_b -i$newton -o$overgrid -I TI TE traj data results/reco results/sens | tee -a nist.log

# FIXME: R2starmap is scaled in post. By purpose?
./post_nist.sh -D $TD -r $NBR results/reco results/reco_maps results/watert1map results/R2starmap results/fB0map

# Run B0 Reference Reco
./b0map/load_ref_b0map.sh results/b0map

# Improve testing: Avoid influence of background noise on NRMSE
bart cabs rois_and_masks/img_mask tmp_mask	# Avoid nans in nrmse, FIXME: Replace mask with one without nans inside
bart fmac tmp_mask results/b0map results/b0map_testing
