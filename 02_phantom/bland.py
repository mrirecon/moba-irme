#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
import cfl

import matplotlib.pyplot as plt
import numpy as np


def bland_altman_plot_1(data1, data2, out_file, yliml, ylimm, label=False, *args, **kwargs):

	plt.rcParams.update({'font.size': 36, 'lines.linewidth': 8})

	data1     = np.asarray(data1)
	data2     = np.asarray(data2)
	mean      = np.mean([data1, data2], axis=0)
	diff      = data1 - data2                   # Difference between data1 and data2
	md        = np.mean(diff)                   # Mean of the difference
	sd        = np.std(diff, axis=0)            # Standard deviation of the difference
	print(md)
	print(sd)

	print(diff)

	plt.figure(figsize=(10/1.5, 9/1.5), dpi=80)
	plt.scatter(mean, diff, s=120, c='black', *args, **kwargs)
	plt.axhline(md,           color='blue', linestyle='--', zorder=-1)
	plt.axhline(md + 1.96*sd, color='red', linestyle='--', zorder=-1)
	plt.axhline(md - 1.96*sd, color='red', linestyle='--', zorder=-1)
	plt.ylim(yliml, ylimm)

	if (label):
		plt.text(np.max(mean), np.max(md + 1.96*sd), "Mean + 1.96 SD", horizontalalignment='right', verticalalignment='bottom', color = "red")

		plt.text(np.max(mean), np.max(md - 1.96*sd), "Mean - 1.96 SD", horizontalalignment='right', verticalalignment='top', color = "red")

	# plt.rcParams.update({'font.size': 38, 'font.sans-serif':'Arial'})


##################################################################


if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 5):
		print( "Function for creating Bland-Altman plots" )
		print( "Usage: bland.py <joined-rois>" )
		exit()

	rois_t1ref = np.real(cfl.readcfl(sys.argv[1]).squeeze())
	rois_r2sref = np.real(cfl.readcfl(sys.argv[2]).squeeze())
	rois_t1 = np.real(cfl.readcfl(sys.argv[3]).squeeze())
	rois_r2s = np.real(cfl.readcfl(sys.argv[4]).squeeze())

	rois_t1ref[0 == rois_t1ref] = np.nan
	rois_r2sref[0 == rois_r2sref] = np.nan
	rois_t1[0 == rois_t1] = np.nan
	rois_r2s[0 == rois_r2s] = np.nan

	reft1 = np.nanmean(rois_t1ref, axis=(0, 1))
	refr2s = np.nanmean(rois_r2sref, axis=(0, 1))
	t1 = np.nanmean(rois_t1, axis=(0, 1))
	r2s = np.nanmean(rois_r2s, axis=(0, 1))

	# Water T1: Ref vs. Scan 1, VOL97

	out_file = "bland_T1_phantom_ref.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(reft1*1000, t1*1000, out_file, -100, 100) # "*1000" [s] -> [ms]
	# ax.set_xticks(np.arange(600, 1600, 400))
	ax.grid()
	plt.xlabel("$T_{1}$ Average / ms")
	plt.ylabel("$T_{1}$ Difference / ms \n Ref. - Proposed")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)

	# R2s: Ref vs. Scan 1, VOL97

	out_file = "bland_R2s_phantom_ref.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(refr2s, r2s, out_file, -5, 5, True)
	ax.set_xticks(np.arange(14, 23, 2))
	ax.grid()
	plt.xlabel("$R_{2}^{*}$ Average / s$^{-1}$")
	plt.ylabel("$R_{2}^{*}$ Difference / s$^{-1}$ \n Ref - Proposed")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)

