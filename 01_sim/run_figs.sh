#!/bin/bash


set -euBx
set -o pipefail

# Run reconstructions

./run.sh

# Create mask

READ=$(bart show -d 0 results/reco_maps)

bart phantom -T -x$READ mask

# Visualization of A

# T1w
bart fmac mask results/watert1map watert1map_masked
python3 save_maps.py watert1map_masked viridis 0 3 watert1map.png

# T1f
bart fmac mask results/fatt1map fatt1map_masked
python3 save_maps.py fatt1map_masked viridis 0 3 fatt1map.png

# R2*
bart fmac mask results/r2starmap r2starmap_masked
python3 save_maps.py r2starmap_masked magma 0 100 r2starmap.png

# B0
bart fmac mask results/fB0map fB0map_masked
python3 save_maps.py fB0map_masked RdBu_r -50 50 fB0map.png 0

# FF
bart extract 6 1 2 results/reco_maps reco_maps_M0w
bart extract 6 4 5 results/reco_maps reco_maps_M0f
bart scale 0.5 reco_maps_M0f reco_maps_M0f2

./fatfrac.sh reco_maps_M0w reco_maps_M0f2 wf_frac_simu

bart cabs wf_frac_simu wf_frac_simu_abs 
bart fmac mask wf_frac_simu_abs wf_frac_simu_masked2
python3 save_maps.py wf_frac_simu_masked2 hot 0 100 wf_frac_simu_masked.png # [%]

# Create ROIs

bart phantom -T -x$READ -b tmp

N_REGIONS=$(bart show -d 6 tmp)

# bart extract 6 1 $N_REGIONS tmp tmp2 # Remove water background from ROIs

bart morphop -e 3 tmp rois # Shrink ROIs slightly to avoid edge artifacts

# ROI Analysis for Subfigure B

bart roistat -M rois watert1map_masked watert1_rois

bart roistat -M rois fatt1map_masked fatt1_rois

bart roistat -M rois r2starmap_masked r2star_rois

bart roistat -M rois wf_frac_simu_masked2 wf_frac_simu_rois

bart roistat -M rois fB0map_masked b0_rois

bart join 11 watert1_rois fatt1_rois r2star_rois wf_frac_simu_rois b0_rois meas_values

# Join all ROI analysis results

bart join 12 results/ref_values meas_values values_combined

# Create Bland-Altman Plots

python3 bland.py values_combined

# Figure C

FF_VALUES=(0 0.05 0.1 0.15 0.2 0.25 0.3)

bart vec -- "${FF_VALUES[@]}" ref_ff

# Phases
PH=("in" "out")

NAMES_IN=()
NAMES_OUT=()

for FF in "${FF_VALUES[@]}";
do
	for i in `seq 0 $((${#PH[@]}-1))`;
	do
		FF_r=$(echo $FF | sed -e 's/\./_/')
		echo $FF_r

		# Mask T1 maps and reco
		bart fmac mask results/reco_192_FF${FF}_"${PH[$i]}" reco_FF${FF_r}_"${PH[$i]}"_mask
		bart fmac mask results/t1map_192_FF${FF}_"${PH[$i]}" t1map_FF${FF_r}_"${PH[$i]}"_mask

		# Generate T1 Maps
		python3 save_maps.py t1map_FF${FF_r}_"${PH[$i]}"_mask viridis 0 3 t1map_FF${FF_r}_"${PH[$i]}".png

		# Extract ROIs
		# bart roistat -M rois t1map_FF${FF}_"${PH[$i]}"_mask t1map_rois_FF${FF}_"${PH[$i]}" # Problem with NaNs in roistat?
		bart fmac rois t1map_FF${FF_r}_"${PH[$i]}"_mask t1map_rois_FF${FF_r}_"${PH[$i]}"

		if [[ "in" == "${PH[$i]}" ]];
		then
			python3 bland2.py values_combined t1map_rois_FF${FF_r}_"${PH[$i]}" bland_t1map_FF${FF_r}_"${PH[$i]}" "In-phase"

			NAMES_IN+="t1map_rois_FF${FF_r}_"${PH[$i]}" "
		else
			python3 bland2.py values_combined t1map_rois_FF${FF_r}_"${PH[$i]}" bland_t1map_FF${FF_r}_"${PH[$i]}" "Out-of-phase"

			NAMES_OUT+="t1map_rois_FF${FF_r}_"${PH[$i]}" "
		fi
	done
done

# Figure D

bart join 11 $(echo "${NAMES_IN[@]}") joined_in_rois
bart join 11 $(echo "${NAMES_OUT[@]}") joined_out_rois

bart join 12 joined_in_rois joined_out_rois joined_rois

python3 rel_diff.py results/ref_values ref_ff joined_rois rel_diff_FF_T1


# Create final Figure

inkscape figure/figure_part_A.svg --export-background=white --export-filename=figure_A.pdf
inkscape figure/figure_part_C_1.svg --export-background=white --export-filename=figure_C_1.pdf
inkscape figure/figure_part_C_2.svg --export-background=white --export-filename=figure_C_2.pdf

inkscape figure/A.svg --export-background=white --export-filename=A.pdf
inkscape figure/B.svg --export-background=white --export-filename=B.pdf
inkscape figure/C.svg --export-background=white --export-filename=C.pdf
inkscape figure/D.svg --export-background=white --export-filename=D.pdf

pdflatex --shell-escape figure.tex

mv figure.pdf figure/figure_01.pdf

# EPS conversion
inkscape figure/figure_01.pdf --export-filename=figure/figure_01.eps

# PNG conversion
inkscape figure/figure_01.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_01.png

rm *.{cfl,hdr,pdf,png}