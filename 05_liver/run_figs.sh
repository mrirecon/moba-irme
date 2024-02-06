#!/bin/bash

set -eux

# Run reconstructions

./run.sh

# Visualizations

datasets=($(ls data/*.cfl | sed -e 's/\.cfl//'))

for file in "${datasets[@]}";
do
	NAME=$(basename $file)

	# All datasets except the single echo one
	if [ "liver_ss_t1ref" != $NAME ]
	then

		if [ "liver_1-6_a" == $NAME ]
		then
			SCAN=scan1

		elif [ "liver_1-6_b" == $NAME ]
		then
			SCAN=scan2
		else
			echo "Filename can not be assigned to scan!"
			exit 1
		fi

		# IR Mulit-Echo Datasets

		# Water T1
		bart fmac rois_and_masks/${SCAN}/img_mask results/watert1map_liver_${NAME} watert1map_liver_${NAME}_masked
		python3 save_maps.py watert1map_liver_${NAME}_masked viridis 0 2 watert1map_${NAME}.png

		# Fat T1
		bart fmac rois_and_masks/${SCAN}/img_mask results/fatt1map_liver_${NAME} fatt1map_liver_${NAME}_masked
		python3 save_maps.py fatt1map_liver_${NAME}_masked viridis 0 2 fatt1map_${NAME}.png

		# R2*
		bart fmac rois_and_masks/${SCAN}/img_mask results/r2starmap_liver_${NAME} r2starmap_liver_${NAME}_masked
		python3 save_maps.py r2starmap_liver_${NAME}_masked magma 0 150 r2starmap_${NAME}.png

		# fB0
		bart fmac rois_and_masks/${SCAN}/img_mask results/fB0map_liver_${NAME} fB0map_liver_${NAME}_masked
		python3 save_maps.py fB0map_liver_${NAME}_masked RdBu_r -150 150 fB0mapmap_${NAME}.png

		# Fat Fraction
		bart fmac rois_and_masks/${SCAN}/img_mask results/reco_liver_maps_${NAME} reco_liver_maps_${NAME}_masked

		bart extract 6 0 1 results/reco_liver_maps_${NAME} water_joint
		bart extract 6 3 4 results/reco_liver_maps_${NAME} fat_joint

		# Internal Fat scaling of 0.5 needs to be compensated, See FIXME in src/moba/ir_meco.c
		bart scale 0.5 fat_joint fat_joint2

		./fatfrac.sh water_joint fat_joint2 wf_frac_joint

		bart fmac rois_and_masks/${SCAN}/img_mask wf_frac_joint wf_frac_joint_${NAME}_masked

		python3 save_maps.py wf_frac_joint_${NAME}_masked hot 0 100 wf_frac_joint_${NAME}.png


		# Steady-State Reference

		# Fat Fraction
		bart fmac rois_and_masks/${SCAN}/img_mask results/reco_wf_ss_${NAME} results/reco_wf_ss_${NAME}_mask

		bart extract 6 0 1 results/reco_wf_ss_${NAME}_mask W2_ss
		bart extract 6 1 2 results/reco_wf_ss_${NAME}_mask F2_ss

		./fatfrac.sh W2_ss F2_ss wf2_frac_ss

		bart fmac rois_and_masks/${SCAN}/img_mask wf2_frac_ss wf2_frac_ss_${NAME}_masked2

		python3 save_maps.py wf2_frac_ss_${NAME}_masked2 hot 0 100 ss_ref_wf_frac_${NAME}.png

		# R2*
		bart extract 6 2 3 results/reco_wf_ss_${NAME}_mask R2s2_ss_${NAME}

		python3 save_maps.py R2s2_ss_${NAME} magma 0 150 ss_ref_r2starmap_${NAME}.png

		# fB0
		bart extract 6 3 4 results/reco_wf_ss_${NAME}_mask B0_ss2_${NAME}

		python3 save_maps.py B0_ss2_${NAME} RdBu_r -150 150 ss_ref_fB0map_${NAME}.png

		# Water M0
		bart slice 6 0 results/reco_liver_${NAME} m0water_l_${NAME}
		bart resize -c 0 200 1 200 m0water_l_${NAME} m0water_${NAME}
		bart fmac rois_and_masks/${SCAN}/img_mask m0water_${NAME} m0water_${NAME}_masked
		python3 save_maps_abs.py m0water_${NAME}_masked gray 0 2 m0water_${NAME}.png

		# Fat M0
		bart slice 6 3 results/reco_liver_${NAME} m0fat_l_${NAME}
		bart resize -c 0 200 1 200 m0fat_l_${NAME} m0fat_${NAME}
		bart fmac rois_and_masks/${SCAN}/img_mask m0fat_${NAME} m0fat_${NAME}_masked
		python3 save_maps_abs.py m0fat_${NAME}_masked gray 0 2 m0fat_${NAME}.png
	fi
done

# Single Echo T1 Reference from Scan 1

bart fmac rois_and_masks/scan1/img_mask results/ss-liver-t1map2 ss-liver-t1map2

python3 save_maps.py ss-liver-t1map2 viridis 0 2 ss_ref_t1map_liver.png


# Extract ROIs from Scans

for file in "${datasets[@]}";
do
	NAME=$(basename $file)

	# All datasets except the single echo one
	if [ "liver_ss_t1ref" != $NAME ]
	then

		if [ "liver_1-6_a" == $NAME ]
		then
			SCAN=scan1

		elif [ "liver_1-6_b" == $NAME ]
		then
			SCAN=scan2
		else
			echo "Filename can not be assigned to scan!"
			exit 1
		fi

		# T1
		bart fmac rois_and_masks/${SCAN}/rois_t1 watert1map_liver_${NAME}_masked rois_watert1map_liver_${NAME}

		# R2s
		bart fmac rois_and_masks/${SCAN}/rois_r2s r2starmap_liver_${NAME}_masked rois_r2starmap_liver_${NAME}

		# Fat Fraction
		bart fmac rois_and_masks/${SCAN}/rois_FF wf_frac_joint_${NAME}_masked rois_wf_frac_joint_${NAME}

		bart join 11 rois_watert1map_liver_${NAME} rois_r2starmap_liver_${NAME} rois_wf_frac_joint_${NAME} rois_${NAME}
	fi
done

# Extract ROIs from References

NAME=liver_1-6_a
SCAN=scan1

bart fmac rois_and_masks/scan1/rois_t1_single_echo ss-liver-t1map2 rois_t1_ref

bart fmac rois_and_masks/${SCAN}/rois_r2s R2s2_ss_${NAME} rois_r2s_ref

bart fmac rois_and_masks/${SCAN}/rois_FF wf2_frac_ss_${NAME}_masked2 rois_ff_ref

bart join 11 rois_t1_ref rois_r2s_ref rois_ff_ref rois_ref

# Join all ROI analysis results

bart join 12 rois_ref rois_liver_1-6_a rois_liver_1-6_b rois_combined

# Create Bland-Altman Plots

python3 bland.py rois_combined

# Create final Figure

inkscape figure/figure_05_part_A.svg --export-background=white --export-filename=figure_05_part_A.pdf

inkscape figure/figure_s04.svg --export-background=white --export-filename=figure_s04.pdf

inkscape figure/figure_s03_part_B.svg --export-background=white --export-filename=figure_s03_part_B.pdf

inkscape figure/A.svg --export-background=white --export-filename=A.pdf
inkscape figure/B.svg --export-background=white --export-filename=B.pdf
inkscape figure/C.svg --export-background=white --export-filename=C.pdf

pdflatex --shell-escape figure_05.tex

mv figure_05.pdf figure/figure_05.pdf
mv figure_s04.pdf figure/figure_s04.pdf
mv figure_s03_part_B.pdf figure/figure_s03_part_B.pdf

# EPS conversion
inkscape figure/figure_05.pdf --export-filename=figure/figure_05.eps
inkscape figure/figure_s04.pdf --export-filename=figure/figure_s04.eps
inkscape figure/figure_s03_part_B.pdf --export-filename=figure/figure_s03_part_B.eps

# PNG conversion
inkscape figure/figure_05.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_05.png
inkscape figure/figure_s04.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_s04.png
inkscape figure/figure_s03_part_B.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_s03_part_B.png

rm *.{cfl,hdr,pdf,png}


