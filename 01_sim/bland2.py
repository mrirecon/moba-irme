#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
import cfl

import matplotlib.pyplot as plt
import numpy as np


def bland_altman_plot_1(data1, data2, out_file, yliml, ylimm, *args, **kwargs):

	plt.rcParams.update({'font.size': 38, 'lines.linewidth': 8})

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
	plt.axhline(md,           color='blue', linestyle='--',zorder=-1)
	plt.axhline(md + 1.96*sd, color='red', linestyle='--',zorder=-1)
	plt.axhline(md - 1.96*sd, color='red', linestyle='--',zorder=-1)
	plt.ylim(yliml, ylimm)


##################################################################


if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 5):
		print( "Function for creating Bland-Altman plots" )
		print( "Usage: bland.py <joined-ref-values> <meas T1 values> <outfile name> <label>" )
		exit()

	values = np.real(cfl.readcfl(sys.argv[1]).squeeze())
	ref = values[:,:,0]

	meas = np.real(cfl.readcfl(sys.argv[2]).squeeze())
	meas[0 == meas] = np.nan
	mean = np.nanmean(meas, axis=(0, 1))

	print(ref[:,0], mean)

	out_file = sys.argv[3] + ".pdf"

	label = sys.argv[4]

	
	meas = values[:,:,1]

	# Water T1: Ref vs. Meas

	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	bland_altman_plot_1(ref[:,0]*1000, mean*1000, out_file, -3000, 3000) # "*1000" [s] -> [ms]
	# ax.set_xticks(np.arange(600, 1600, 400))
	ax.grid()
	plt.xlabel("$T_1$ Average / ms", fontsize=35)
	plt.ylabel("$T_1$ Difference / ms \n Ref. - " + label, fontsize=35)
	plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)


	
