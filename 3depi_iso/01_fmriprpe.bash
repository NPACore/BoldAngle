#!/usr/bin/env bash

datadir="$(cd "$(dirname "$0")/../Data"; pwd -P)"
export BIDS=$datadir/bids-3depi2x2x2/
../AngleCompare/01_preproc_fmriprep.bash
