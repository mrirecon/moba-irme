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
	plt.axhline(md,           color='blue', linestyle='--',)
	plt.axhline(md + 1.96*sd, color='red', linestyle='--')
	plt.axhline(md - 1.96*sd, color='red', linestyle='--')
	plt.ylim(yliml, ylimm)

	if (label):
		plt.text(np.max(mean), np.max(md + 1.96*sd), "Mean + 1.96 SD", horizontalalignment='right', verticalalignment='bottom', color = "red")

		plt.text(np.max(mean), np.max(md - 1.96*sd), "Mean - 1.96 SD", horizontalalignment='right', verticalalignment='top', color = "red")

##################################################################


if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 2):
		print( "Function for creating Bland-Altman plots" )
		print( "Usage: bland.py <joined-rois>" )
		exit()

	rois = np.real(cfl.readcfl(sys.argv[1]).squeeze())

	rois[0 == rois] = np.nan

	mean = np.nanmean(rois, axis=(0, 1))

	ref = mean[:,:,0]
	scan1 = mean[:,:,1]
	scan2 = mean[:,:,2]

	# Water T1: Ref vs. Scan 1

	out_file = "bland_T1_liver_ref.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(ref[:,0]*1000, scan1[:,0]*1000, out_file, -100, 100) # "*1000" [s] -> [ms]
	# ax.set_xticks(np.arange(600, 1600, 400))
	ax.grid()
	plt.xlabel("$T_{1}$ Average / ms")
	plt.ylabel("$T_{1}$ Difference / ms \n Ref. - Proposed")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)

	# R2s: Ref vs. Scan 1

	out_file = "bland_R2s_liver_ref.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(ref[:,1], scan1[:,1], out_file, -10, 10)
	# ax.set_xticks(np.arange(14, 23, 2))
	ax.grid()
	plt.xlabel("$R_{2}^{*}$ Average / s$^{-1}$")
	plt.ylabel("$R_{2}^{*}$ Difference / s$^{-1}$ \n Ref. - Proposed")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)

	# WF frac: Ref vs. Scan 1

	out_file = "bland_FF_liver_ref.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(ref[:,2], scan1[:,2], out_file, -5, 5)
	# ax.set_xticks(np.arange(0, np.log10(200), np.log10(40)))
	ax.grid()
	plt.xlabel("FF Average / $ \%$")
	plt.ylabel("FF Difference / $ \%$ \n Ref. - Proposed")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)

	# Water T1: Scan 2 vs. Scan 1

	out_file = "bland_T1_liver_scan.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(scan2[:,0]*1000, scan1[:,0]*1000, out_file, -100, 100, True) # "*1000" [s] -> [ms]
	# ax.set_xticks(np.arange(600, 1600, 400))
	ax.grid()
	plt.xlabel("$T_{1}$ Average / ms")
	plt.ylabel("$T_{1}$ Difference / ms \n Scan #2 - Scan #1")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)

	# R2s: Scan 1 vs. Scan 2

	out_file = "bland_R2s_liver_scan.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(scan2[:,1], scan1[:,1], out_file, -10, 10)
	# ax.set_xticks(np.arange(14, 23, 2))
	ax.grid()
	plt.xlabel("$R_{2}^{*}$ Average / s$^{-1}$")
	plt.ylabel("$R_{2}^{*}$ Difference / s$^{-1}$ \n Scan #2 - Scan #1")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)

	# WF frac: Scan 1 vs. Scan 2

	out_file = "bland_FF_liver_scan.pdf"
	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(scan2[:,2], scan1[:,2], out_file, -5, 5)
	# ax.set_xticks(np.arange(0, np.log10(200), np.log10(40)))
	ax.grid()
	plt.xlabel("FF Average / $ \%$")
	plt.ylabel("FF Difference / $ \%$ \n Scan #2 - Scan #1")
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)
	

