# Model-Based Reconstruction for Joint Estimation of $T_{1}$, $R_{2}^{*}$ and $B_{0}$ Field Maps Using Single-Shot Inversion-Recovery Multi-Echo Radial FLASH


This repository includes the scripts to create the Figures for the publication

> #### Model-Based Reconstruction for Joint Estimation of $T_{1}$, $R_{2}^{*}$ and $B_{0}$ Field Maps Using Single-Shot Inversion-Recovery Multi-Echo Radial FLASH
> Wang, X, Scholand, N, Tan, Z, Mackner, D, Telezki, V, Blumenthal, M, Schaten, P, Uecker, M.
>
> Submitted to Magnetic Resonance in Medicine
> 
> [Preprint on ArXiv (DOI: ????)](future-link)


## Requirements
This repository has been tested on Debian 12, but is assumed to work on other Linux-based operating systems, too.

#### Reconstruction
Pre-processing, reconstruction and post-processing is performed with the [BART toolbox](https://github.com/mrirecon/bart).
The provided scripts are compatible with commit `b9f2c33b` or later.
If you experience any compatibility problems with later BART versions please contact us!

For running the reconstructions access to a GPU is recommended.
If the CPU should be used, please remove `-g` flags from all `bart pics ...`, `bart nufft ...`, and `bart moba ...` calls.

#### Visualizations
The visualizations have been tested with `Python` (version 3.9.2) and require `numpy`, `matplotlib`, `sys`, and `os`. Full list of requirements can be found in `requirements.txt`. Install using pip
```
pip install -r requirements.txt
```
 Ensure to have set a DISPLAY variable, when the results should be visualized.
The figures require `pdflatex`, which was tested on version 3.14159265-2.6-1.40.21 (TeX Live 2020/Debian). All additionally required TeX packages can be found in `installed_texlive_packages.txt`.
Install using tlmgr
```
tlmgr install --usermode `cat installed_texlive_packages.txt`
```
Additionally, the command line tool from `Inkscape` 1.2.2 (b0a8486541, 2022-12-01) is needed.

#### Data
The data is hosted on [ZENODO](https://zenodo.org/) and **must be downloaded first**.

* Manual download: https://doi.org/10.5281/zenodo.10529421
* Download via script: Run the download script in the `./data` folder.
  * **All** files: `bash load-all.sh`
  * **Individual** files: `bash load.sh 10529421 <FILENAME> . `

Note: The data must be stored in the `./data` folder!


## Folders
Each folder contains a README file explaining how the figure can be reproduced.

## Runtime

|    CPU   |   GPU   | **Runtime** [min] |
| -------- | ------- | ------- |
|  AMD EPYC 9334 32-Core  | NVIDIA H100 80G GPU   | **92** |
| Intel Xeon Gold 6132 | NVIDIA Tesla V100 SXM2 32 GB $^*$   | **301** |

$^*$ It was found that the maximal memory requirement on the GPU was 60 GB VRAM.
Therefore, global memory needs to be turned on for GPUs with less memory prolonging the reconstruction time. The option can be specified in BART using `BART_GPU_GLOBAL_MEMORY=1`.

## Feedback
Please feel free to send us feedback about this scripts!
We would be happy to learn how to improve this and future script publications.


## License
This work is licensed under a **Creative Commons Attribution 4.0 International License**.
You should have received a copy of the license along with this
work. If not, see <https://creativecommons.org/licenses/by/4.0/>.
