#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import numpy as np

import sys
import os
sys.path.insert(0, os.path.join(os.environ['TOOLBOX_PATH'], 'python'))
import cfl

import matplotlib as mpl
from matplotlib.colors import ListedColormap
import matplotlib.pyplot as plt


class save_maps(object):
   
        
    def __init__(self, image, colorbartype, lowerbound, upperbound, outfile):
        
        colorbartype =  str(colorbartype)
               
        viridis = mpl.colormaps[colorbartype]
        newcolors = viridis(np.linspace(0, 1, 256))
        dark = np.array([0.0, 0.0, 0.0, 1])
        newcolors[:1, :] = dark
        newcmp = ListedColormap(newcolors)
        
        plt.figure()
        plt.imshow(image,interpolation='nearest',cmap=newcmp,vmin=lowerbound, vmax=upperbound)
        # plt.show()
        
        plt.imsave(outfile, image, format="png",cmap=newcmp,vmin=lowerbound, vmax=upperbound);

if __name__ == "__main__":
    
    #Error if wrong number of parameters
    if( len(sys.argv) != 6):
        print( "Function for saving quantitative MR maps with colormap" )
        print( "Usage: save_maps.py <input image> <colorbartype(e.g., viridis)> <lowerbound> <upperbound> <outfile>" )
        exit()
        
    image = np.abs(cfl.readcfl(sys.argv[1]).squeeze())
    image[np.isnan(image)] = 0

    save_maps(image, sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
