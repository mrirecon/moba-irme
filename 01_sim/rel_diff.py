#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
import cfl

import matplotlib.pyplot as plt
import numpy as np

if __name__ == "__main__":

	#Error if wrong number of parameters
	if( len(sys.argv) != 5):
		print( "Function for create rel. diff. plot" )
		print( "Usage: bland.py <joined-ref-values> <ref FF> <meas T1 values> <outfile name>" )
		exit()

	ref = np.real(cfl.readcfl(sys.argv[1]).squeeze())

	ref_ff = np.real(cfl.readcfl(sys.argv[2]).squeeze()) * 100 # [%]
	
	meas = np.real(cfl.readcfl(sys.argv[3]).squeeze())
	meas[0 == meas] = np.nan
	mean = np.nanmean(meas, axis=(0, 1))

	print(np.shape(mean))

	# Water T1: Ref vs. Meas

	for i in range(0, np.shape(ref)[0]):

		current_T1_ref = ref[i,0] # [s]
		current_T1_ref *= 1000 # [s] -> [ms]

		print("Current T1 = " + str(int(np.round(current_T1_ref))))
		print(mean[i,:,0])

		diff_in = current_T1_ref - mean[i,:,0] * 1000 # *1000 for [s] -> [ms]
		diff_out = current_T1_ref - mean[i,:,1] * 1000 # *1000 for [s] -> [ms]

		# Relative Difference
		diff_in /= current_T1_ref
		diff_out /= current_T1_ref

		diff_in *= 100 # [%]
		diff_out *= 100 # [%]

		out_file = sys.argv[4] + "_" + str(int(np.round(current_T1_ref))) + ".pdf"

		fig = plt.figure(figsize=(10/1.5, 9/1.5), dpi=80)
		plt.rcParams.update({'font.size': 30, 'lines.linewidth': 4, 'lines.markersize' : 15})
		ax = fig.add_subplot(1, 1, 1)

		# In-phase
		plt.plot(ref_ff, diff_in, '--ro', label="In-phase")
		# Out-phase
		plt.plot(ref_ff, diff_out, '--b^', label="Out-of-phase")

		ax.set_ylim([-100, 100])
		ax.set_xticks(np.arange(0, 35, 5))

		ax.legend(fancybox=True, framealpha=0.5)

		plt.xlabel("Fat Fraction / % \n ($T_1$ = " + str(int(np.round(current_T1_ref))) + " ms)")
		plt.ylabel("Relative $T_1$ Error / %")
		plt.savefig(out_file, dpi=350, bbox_inches='tight',pad_inches = 0)


	
