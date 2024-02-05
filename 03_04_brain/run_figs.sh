#!/bin/bash

set -euBx

# Run reconstructions

./run.sh

# Visualizations

plot_maps()
{
	MASK=$1
	NAME=$2

	# Water T1
	bart fmac $MASK results/watert1map2_${NAME} watert1map_${NAME}_masked
	python3 save_maps.py watert1map_${NAME}_masked viridis 0 2 watert1map_${NAME}.png

	# Fat T1
	bart fmac $MASK results/fatt1map2_${NAME} fatt1map_${NAME}_masked
	python3 save_maps.py fatt1map_${NAME}_masked viridis 0 2 fatt1map_${NAME}.png

	# R2*
	bart fmac $MASK results/r2starmap2_${NAME} r2starmap_${NAME}_masked
	python3 save_maps.py r2starmap_${NAME}_masked magma 0 50 r2starmap_${NAME}.png

	# fB0
	bart fmac $MASK results/fB0map2_${NAME} fB0map_${NAME}_masked
	python3 save_maps.py fB0map_${NAME}_masked RdBu_r -150 150 fB0map_${NAME}.png

	# Water M0
	bart slice 6 0 results/reco_maps_${NAME} m0water_${NAME}
	bart fmac $MASK m0water_${NAME} m0water_${NAME}_masked
	python3 save_maps_abs.py m0water_${NAME}_masked gray 0 2 m0water_${NAME}.png

	# Fat M0
	bart slice 6 3 results/reco_maps_${NAME} m0fat_${NAME}
	bart fmac $MASK m0fat_${NAME} m0fat_${NAME}_masked
	python3 save_maps_abs.py m0fat_${NAME}_masked gray 0 2 m0fat_${NAME}.png
}

extract_rois()
{
	ROIS_T1=$1
	ROIS_R2s=$2
	NAME=$3

	# Water T1
	bart fmac $ROIS_T1 results/watert1map2_${NAME} rois_watert1map_${NAME}

	# R2*
	bart fmac $ROIS_R2s results/r2starmap2_${NAME} rois_r2starmap_${NAME}

	# Join
	bart join 11 rois_watert1map_${NAME} rois_r2starmap_${NAME} rois_${NAME}
}


plot_maps rois_and_masks/vol96/scan1/img_mask brain_ss_vol96_1

plot_maps rois_and_masks/vol96/scan2/img_mask brain_ss_vol96_2

plot_maps rois_and_masks/vol97/scan1/img_mask brain_ss_vol97_1

plot_maps rois_and_masks/vol97/scan2/img_mask brain_ss_vol97_2

# Single-echo reference T1 map

bart fmac rois_and_masks/vol97/scan1/img_mask results/ss-brain-t1map2 ss-brain-t1map2

python3 save_maps.py ss-brain-t1map2 viridis 0 2 ref-ss-brain-t1map.png

# Plot Cartesian Reference for R2s
python3 save_maps.py rois_and_masks/vol97/ref/r2star_Cartesian magma 0 50 ref-cartesian-r2smap.png

# Plot Cartesian Reference for B0

python3 save_maps.py results/b0map RdBu_r -150 150 ref-cartesian-B0map.png

# Extract Reference ROIs

bart fmac rois_and_masks/vol97/scan1/rois_t1 ss-brain-t1map2 rois_t1_ref

bart fmac rois_and_masks/vol97/ref/rois_r2s_Cartesian rois_and_masks/vol97/ref/r2star_Cartesian rois_r2s_ref

bart join 11 rois_t1_ref rois_r2s_ref rois_ref

# Extract ROIs of IR ME Scans

# FIXME: Not used R2s ROIs?
extract_rois rois_and_masks/vol96/scan1/rois_{t1,t1} brain_ss_vol96_1

extract_rois rois_and_masks/vol96/scan2/rois_{t1,t1} brain_ss_vol96_2

extract_rois rois_and_masks/vol97/scan1/rois_{t1,t1} brain_ss_vol97_1

extract_rois rois_and_masks/vol97/scan2/rois_{t1,t1} brain_ss_vol97_2

# Join all ROI analysis results

bart join 12 rois_ref rois_brain_ss_vol96_1 rois_brain_ss_vol96_2 rois_brain_ss_vol97_1 rois_brain_ss_vol97_2 rois_combined

# Create Bland-Altman Plots

python3 bland.py rois_combined


# Create final Figure

inkscape figure/figure_03_part_A.svg --export-background=white --export-filename=figure_03_A.pdf

inkscape figure/A.svg --export-background=white --export-filename=A.pdf
inkscape figure/B.svg --export-background=white --export-filename=B.pdf

pdflatex --shell-escape figure_03.tex

inkscape figure/figure_04_part_A.svg --export-background=white --export-filename=figure_04_A.pdf

pdflatex --shell-escape figure_04.tex

inkscape figure/figure_s03_part_A.svg --export-background=white --export-filename=figure_s03_part_A.pdf

mv figure_03.pdf figure/figure_03.pdf
mv figure_04.pdf figure/figure_04.pdf
mv figure_s03_part_A.pdf figure/figure_s03_part_A.pdf

# EPS conversion
inkscape figure/figure_03.pdf --export-filename=figure/figure_03.eps
inkscape figure/figure_04.pdf --export-filename=figure/figure_04.eps
inkscape figure/figure_s03_part_A.pdf --export-filename=figure/figure_s03_part_A.eps

# PNG conversion
inkscape figure/figure_03.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_03.png
inkscape figure/figure_04.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_04.png
inkscape figure/figure_s03_part_A.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_s03_part_A.png

rm *.{cfl,hdr,pdf,png}
