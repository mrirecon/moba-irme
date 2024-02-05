#!/bin/bash

set -eux

# Estimate absolute paths

FULL_PATH=$(realpath ${0})
ABS_PATH=$(dirname ${FULL_PATH})

FILES=(
	liver_1-6_a
	liver_1-6_b
	liver_ss_t1ref
	)

OUT=(
	liver_1-6_a
	liver_1-6_b
	liver_ss_t1ref
	)

source ${ABS_PATH}/../../utils/data_loc.sh

for (( i=0; i<${#FILES[@]}; i++ ));
do
	if [[ ! -f "${ABS_PATH}/${OUT[$i]}.cfl" ]];
	then
		if [[ -f $DATA_LOC/${FILES[$i]}".cfl" ]];
		then
			bart copy $DATA_LOC/${FILES[$i]} ${ABS_PATH}/${OUT[$i]}
		else
			bart copy ${ABS_PATH}/../../data/${FILES[$i]} ${ABS_PATH}/${OUT[$i]}
		fi

		echo "Generated output file: ${ABS_PATH}/${OUT[$i]}.{cfl,hdr}" >&2
	fi
done