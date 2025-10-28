#!/usr/bin/env bash
test -r ./maxangle_mni/sub-1_tsnr-all4d.nii.gz ||
 3dTcat -prefix ./maxangle_mni/sub-1_tsnr-all4d.nii.gz \
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
  ../FmapCorrect/angle_at_max.py  \
        --nosd \
        -l ../FmapCorrect/angle.txt \
        -i ./maxangle_mni/sub-1_tsnr-all4d.nii.gz  \
        -m ../Data/preproc/fmriprep-25.2.3/sub-1/func/sub-1_task-rest0_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz  \
        -o ./maxangle_mni/sub-1_angleatmax-tsnr.nii.gz 

test -r maxangle_mni/tsnr-min.nii.gz ||
 3dTstat \
  -prefix maxangle_mni/tsnr-min.nii.gz \
  -min ./maxangle_mni/sub-1_tsnr-all4d.nii.gz 
test -r maxangle_mni/tsnr-max.nii.gz ||
 3dTstat \
  -prefix maxangle_mni/tsnr-max.nii.gz \
  -max ./maxangle_mni/sub-1_tsnr-all4d.nii.gz 

3dcalc -n maxangle_mni/tsnr-min.nii.gz\
       -x maxangle_mni/tsnr-max.nii.gz\
       -expr 'x-n' \
       -prefix maxangle_mni/tsnr-range.nii.gz
