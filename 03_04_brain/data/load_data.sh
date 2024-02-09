#!/bin/bash

set -euBx
set -o pipefail

# Estimate absolute paths

FULL_PATH=$(realpath ${0})
ABS_PATH=$(dirname ${FULL_PATH})

FILES=(
	brain_ss_vol96_1
	brain_ss_vol96_2
	brain_ss_vol97_1
	brain_ss_vol97_2
	brain_ss_vol97_t1ref
	brain_vol97_b0ref
	)

OUT=(
	brain_ss_vol96_1
	brain_ss_vol96_2
	brain_ss_vol97_1
	brain_ss_vol97_2
	brain_ss_vol97_t1ref
	brain_vol97_b0ref
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
