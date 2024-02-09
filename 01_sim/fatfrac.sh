#!/bin/bash

set -euBx
set -o pipefail

helpstr=$(cat <<- EOF
compute fat fraction
EOF
)

usage="Usage: $0 [-h] <input water> <input fat> <output fatfrac>"

while getopts "h" opt; do
	case $opt in
	h) 
		echo "$usage"
		echo "$helpstr"
		exit 0 
		;;
	\?)
		echo "$usage" >&2
		exit 1
		;;
	esac
done

shift $(($OPTIND -1 ))

WATER=$(readlink -f "$1") # INPUT water
FAT=$(readlink -f "$2")   # INPUT fat

FF=$(readlink -f "$3")   # OUTPUT FF


# --- |W + F| ---
bart saxpy 1 $WATER $FAT tempff_inphase
bart cabs tempff_inphase tempff_inphase_abs
bart spow -- -1. tempff_inphase_abs tempff_deno

# --- |F| ---
bart cabs $FAT tempff_fat

# --- |F / (W + F)|---
bart fmac tempff_fat tempff_deno tempff_ff

# --- percentage ---
bart scale 100. tempff_ff $FF

rm tempff_*.{cfl,hdr}
