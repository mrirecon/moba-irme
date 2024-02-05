#!/bin/bash

set -B

#10.5281/zenodo.10529421
ZENODO_RECORD=10529421

FILES=(
	nist
	nist_b0ref
	brain_ss_vol96_1
	brain_ss_vol96_2
	brain_ss_vol97_1
	brain_ss_vol97_2
	brain_ss_vol97_t1ref
	brain_vol97_b0ref
	liver_1-6_a
	liver_1-6_b
	liver_ss_t1ref
	)

for i in  "${FILES[@]}";
do

	./load-cfl.sh ${ZENODO_RECORD} ${i} .
done
