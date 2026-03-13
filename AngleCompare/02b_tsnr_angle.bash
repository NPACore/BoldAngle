#!/usr/bin/env bash

# 20260312-  for 3depi
mkdir -p ./maxangle_mni/3depi/
skip-exist ./maxangle_mni/3depi/sub-1_tsnr-3depiall4d.nii.gz \
  dryrun 3dTcat -prefix __SKIPFILE \
     ../Data/tsnr/3depi/sub-1_task-{n40,n33,n13,13,20}_acq-3d_tsnr.nii.gz
printf "%s\n" -40 -33 -13 13 20 | drytee ./maxangle_mni/3depi/angles.txt
skip-exist ./maxangle_mni/3depi/sub-1_angleatmax-tsnr.nii.gz  \
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ./maxangle_mni/3depi/angles.txt \
        -i ./maxangle_mni/3depi/sub-1_tsnr-3depiall4d.nii.gz  \
        -m ../Data/preproc/bids-3depi/fmriprep-25.2.3/sub-1/func/sub-1_task-13_acq-3d_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz \
        -o __SKIPFILE

# Oct 27 2025
test -r ./maxangle_mni/sub-1_tsnr-all4d.nii.gz ||
 dryrun 3dTcat -prefix ./maxangle_mni/sub-1_tsnr-all4d.nii.gz \
        ../Data/tsnr/sub-1_task-restn39_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn33_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn26_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn19_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn13_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-restn6_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest0_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest6_tsnr.nii.gz\
        ../Data/tsnr/sub-1_task-rest13_tsnr.nii.gz \
        ../Data/tsnr/sub-1_task-rest20_tsnr.nii.gz

test -r ./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz  ||
  dryrun ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ../FmapCorrect/angle.txt \
        -i ./maxangle_mni/sub-1_tsnr-all4d.nii.gz  \
        -m ../Data/preproc/fmriprep-25.2.3/sub-1/func/sub-1_task-rest0_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o ./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz 

test -r maxangle_mni/tsnr-min.nii.gz ||
 dryrun 3dTstat \
  -prefix maxangle_mni/tsnr-min.nii.gz \
  -min ./maxangle_mni/sub-1_tsnr-all4d.nii.gz 
test -r maxangle_mni/tsnr-max.nii.gz ||
 dryrun 3dTstat \
  -prefix maxangle_mni/tsnr-max.nii.gz \
  -max ./maxangle_mni/sub-1_tsnr-all4d.nii.gz 

skip-exist maxangle_mni/tsnr-range.nii.gz \
dryrun 3dcalc -n maxangle_mni/tsnr-min.nii.gz\
       -x maxangle_mni/tsnr-max.nii.gz\
       -expr 'x-n' \
       -prefix maxangle_mni/tsnr-range.nii.gz
