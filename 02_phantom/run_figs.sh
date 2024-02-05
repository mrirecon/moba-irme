#!/bin/bash

set -eux

./run.sh

# Visualization


## IR Mulit-Echo Datasets

### Water T1
bart fmac rois_and_masks/img_mask results/watert1map watert1map_masked
python3 save_maps.py watert1map_masked viridis 0 3 watert1map.png

### R2*
bart fmac rois_and_masks/img_mask results/R2starmap R2starmap_masked
python3 save_maps.py R2starmap_masked magma 0 200 r2starmap.png

### fB0
bart fmac rois_and_masks/img_mask results/fB0map fB0map_masked
python3 save_maps.py fB0map_masked RdBu_r -50 50 fB0map.png


## Reference

### Water T1
bart scale 0.001 rois_and_masks/reference/t1_se watert1map_ref_tmp # [ms] -> [s]
python3 save_maps.py watert1map_ref_tmp viridis 0 3 ref_watert1map.png # [s]

### R2*
# bart fmac rois_and_masks/img_mask rois_and_masks/reference/r2s_Cartesian R2starmap_masked2
python3 save_maps.py rois_and_masks/reference/r2s_Cartesian magma 0 200 ref_r2starmap.png #[1/s]

### B0
python3 save_maps.py results/b0map RdBu_r -50 50 ref_b0map.png

# Bland-Altman Analysis

## Extract ROIs from References
bart fmac rois_and_masks/reference/rois_t1_se watert1map_ref_tmp rois_t1_ref

bart fmac rois_and_masks/reference/rois_r2s_Cartesian rois_and_masks/reference/r2s_Cartesian rois_r2s_ref

## Extract ROIs from IR ME
bart fmac rois_and_masks/rois_t1 watert1map_masked rois_t1

bart fmac rois_and_masks/rois_r2s R2starmap_masked rois_r2s

# Create Bland-Altman Plots

python3 bland.py rois_t1_ref rois_r2s_ref rois_t1 rois_r2s


# Create final Figure

inkscape figure/figure_part_A.svg --export-background=white --export-filename=figure_A.pdf

inkscape figure/A.svg --export-background=white --export-filename=A.pdf
inkscape figure/B.svg --export-background=white --export-filename=B.pdf

pdflatex --shell-escape figure.tex

mv figure.pdf figure/figure_02.pdf

# EPS conversion
inkscape figure/figure_02.pdf --export-filename=figure/figure_02.eps

# PNG conversion
inkscape figure/figure_02.pdf --export-background=white --export-dpi=300 --export-filename=figure/figure_02.png

rm *.{cfl,hdr,pdf,png}