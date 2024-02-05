#!/bin/bash

usage="Usage: $0 <record> <name> <outdir>"

if [ $# -lt 3 ] ; then

        echo "$usage" >&2
        exit 1
fi

record=$1
name=$2
outdir=$(readlink -f "$3")

if [ ! -d $outdir ] ; then
        echo "Output directory does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

cd ${outdir}
if [[ ! -f ${name}.cfl ]]; then
	echo Downloading ${name}.cfl
	wget -q https://zenodo.org/record/${record}/files/${name}.cfl
fi
if [[ ! -f ${name}.hdr ]]; then
	echo Downloading ${name}.hdr
	wget -q https://zenodo.org/record/${record}/files/${name}.hdr
fi
cat md5sum.txt | grep ${name} | md5sum -c --ignore-missing
